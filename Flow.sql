
-- =============================================
-- Bước 1: Thêm tài khoản & Khách hàng
-- =============================================
PRINT N'--- 1. Thêm Tài khoản & Khách hàng ---';
IF NOT EXISTS (SELECT 1 FROM TaiKhoan WHERE TenDangNhap = 'tung_test_auto')
    EXEC sp_ThemTaiKhoanKhachHang 'tung_test_auto', '123', N'Nguyễn Auto Tùng', '0911222999', '123199999', N'Hà Nội';
DECLARE @KHID VARCHAR(12) = (SELECT TOP 1 IDKhachHang FROM KhachHang WHERE HoTen = N'Nguyễn Auto Tùng' ORDER BY IDKhachHang DESC);
-- Kiểm tra kết quả
SELECT TOP 1 * FROM KhachHang WHERE HoTen = N'Nguyễn Auto Tùng' ORDER BY IDKhachHang DESC;


-- =============================================
-- Bước 2: Thêm Xe
-- =============================================
PRINT N'--- 2. Thêm Xe ---';
BEGIN
    DECLARE @NewKHID_2 VARCHAR(12);
    -- Tự động lấy ID khách hàng vừa tạo (người mới nhất tên Tùng)
    SELECT TOP 1 @NewKHID_2 = IDKhachHang FROM KhachHang WHERE HoTen = N'Nguyễn Auto Tùng' ORDER BY IDKhachHang DESC;
    
    -- Thêm xe
    EXEC sp_ThemXeKhachHang @NewKHID_2, '30A-888.88', 'LX02_O4', 'Civic', 'Honda', N'Trắng';

    -- Kiểm tra
    SELECT * FROM Xe WHERE BienSoXe = '30A-888.88';
    SELECT * FROM KhachHang_Xe WHERE IDXeNo = '30A-888.88' AND IDKhachHangNo = @NewKHID_2;
END


-- =============================================
-- Bước 3: Khách hàng Đặt chỗ
-- =============================================
PRINT N'--- 3. Khách hàng Đặt chỗ ---';
BEGIN
    DECLARE @NewKHID_3 VARCHAR(12);
    SELECT TOP 1 @NewKHID_3 = IDKhachHang FROM KhachHang WHERE HoTen = N'Nguyễn Auto Tùng' ORDER BY IDKhachHang DESC;
    
    DECLARE @ChoDauTest VARCHAR(12) = 'CD0001_A';
    DECLARE @BienSoXeTest VARCHAR(20) = '30A-888.88';

    -- Reset trạng thái chỗ cũ để test (nếu cần)
    UPDATE ChoDauXe SET TrangThai = N'Trống' WHERE IDChoDauXe = @ChoDauTest;
    -- Xóa chi tiết hóa đơn & booking cũ của chỗ này để tránh lỗi khóa ngoại
    DELETE FROM ChiTietHoaDon WHERE IDDatChoNo IN (SELECT IDDatCho FROM DatCho WHERE IDChoDauNo = @ChoDauTest);
    DELETE FROM DatCho WHERE IDChoDauNo = @ChoDauTest;

    -- Thực hiện đặt chỗ
    EXEC sp_KhachHangDatCho @NewKHID_3, @BienSoXeTest, @ChoDauTest, '2026-11-01 08:00', '2026-11-01 17:00';

    -- Kiểm tra trạng thái (Vẫn là Trống vì mới chờ duyệt)
    SELECT TenChoDau, TrangThai FROM ChoDauXe WHERE IDChoDauXe = @ChoDauTest;
END


-- =============================================
-- Bước 4: Nhân viên Duyệt đơn
-- =============================================
PRINT N'--- 4. Nhân viên Duyệt ---';
BEGIN
    EXEC sp_DanhSachChoDuyet; -- Xem danh sách chờ

    DECLARE @NewKHID_4 VARCHAR(12);
    SELECT TOP 1 @NewKHID_4 = IDKhachHang FROM KhachHang WHERE HoTen = N'Nguyễn Auto Tùng' ORDER BY IDKhachHang DESC;

    -- Tự động tìm đơn đặt chỗ đang chờ duyệt của ông Tùng này
    DECLARE @IDDonDat VARCHAR(20) = (SELECT MAX(IDDatCho) FROM DatCho WHERE IDKhachHangNo = @NewKHID_4 AND TrangThai = N'Đang chờ duyệt');

    IF @IDDonDat IS NOT NULL
    BEGIN
        EXEC sp_NhanVienDuyetDatCho @IDDonDat, 'NV001_BV', N'Đã đặt';
        PRINT N'-> Đã duyệt đơn: ' + @IDDonDat;
    END
    ELSE
        PRINT N'-> Không tìm thấy đơn chờ duyệt nào.';

    -- Kiểm tra kết quả: Chỗ phải chuyển sang 'Đã đặt'
    SELECT TenChoDau, TrangThai FROM ChoDauXe WHERE IDChoDauXe = 'CD0001_A';
END

GO
-- =============================================
-- Bước 5: Xe Vào bãi (Check-in)
-- =============================================
PRINT N'--- 5. Xe Vào bãi ---';
BEGIN
    DECLARE @NewKHID_5 VARCHAR(12);
    SELECT TOP 1 @NewKHID_5 = IDKhachHang FROM KhachHang WHERE HoTen = N'Nguyễn Auto Tùng' ORDER BY IDKhachHang DESC;
    DECLARE @BienSoXeTest VARCHAR(20) = '30A-888.88';
    DECLARE @ChoDauTest VARCHAR(12) = 'CD0001_A';

    EXEC sp_XeVaoBai @NewKHID_5, @BienSoXeTest, @ChoDauTest, 'NV001_BV';

    -- Kiểm tra tạo phiếu
    SELECT * FROM PhieuGiuXe WHERE IDXeNo = @BienSoXeTest AND TgianRa IS NULL;
    
    -- Hack thời gian lùi lại 3 tiếng để lát nữa ra bãi tính tiền cho nhiều
    UPDATE PhieuGiuXe 
    SET TgianVao = DATEADD(HOUR, -3, GETDATE()) 
    WHERE IDXeNo = @BienSoXeTest AND TgianRa IS NULL;
END

GO
-- =============================================
-- Bước 6: Xe Ra bãi (Check-out & Tính tiền)
-- =============================================
PRINT N'--- 6. Xe Ra bãi ---';
BEGIN
    DECLARE @BienSoXeTest VARCHAR(20) = '30A-888.88';
    
    -- Tìm phiếu giữ xe đang mở của xe này
    DECLARE @IDPhieu VARCHAR(15) = (SELECT MAX(IDPhieuGiuXe) FROM PhieuGiuXe WHERE IDXeNo = @BienSoXeTest AND TgianRa IS NULL);

    IF @IDPhieu IS NOT NULL
    BEGIN
        EXEC sp_XeRaBai @IDPhieu, 'NV001_BV';
        
        -- Xem hóa đơn vừa tạo
        SELECT * FROM HoaDon WHERE IDHoaDon = (SELECT IDHoaDonNo FROM PhieuGiuXe WHERE IDPhieuGiuXe = @IDPhieu);
        SELECT * FROM ChiTietHoaDon WHERE IDHoaDonNo = (SELECT IDHoaDonNo FROM PhieuGiuXe WHERE IDPhieuGiuXe = @IDPhieu);
        
        -- Kiểm tra chỗ đậu đã nhả ra Trống chưa
        SELECT TenChoDau, TrangThai FROM ChoDauXe WHERE IDChoDauXe = 'CD0001_A';
    END
    ELSE
    BEGIN
        PRINT N'Không tìm thấy phiếu giữ xe nào chưa ra bãi cho xe này.';
    END
END

gO
-- =============================================
-- Bước 7: Test Đăng ký thẻ tháng 
-- =============================================
-------------------XEM GIÁ----------------------
PRINT N'--- 5.1 Kiểm tra giá niêm yết ---';
DECLARE @BienSoXeTest VARCHAR(20) = '30A-888.88';
DECLARE @MaBaiDo VARCHAR(8) = 'BD001';

SELECT 
    kh.HoTen AS [Tên Khách Hàng],
    x.BienSoXe, 
    lx.TenLoaiXe, 
    dbo.fn_LayGiaTheThang(x.BienSoXe, @MaBaiDo) AS [Giá Niêm Yết 1 Tháng]
FROM KhachHang kh
JOIN KhachHang_Xe khx ON kh.IDKhachHang = khx.IDKhachHangNo
JOIN Xe x ON khx.IDXeNo = x.BienSoXe
JOIN LoaiXe lx ON x.IDLoaiXeNo = lx.IDLoaiXe
WHERE kh.HoTen = N'Nguyễn Auto Tùng';
GO
----------------------------ĐĂNG KÝ THẺ THÁNG-------------------
PRINT N'--- 5.2 Thực hiện Đăng ký ---';
DECLARE @KHID_DK VARCHAR(12);
SELECT TOP 1 @KHID_DK = IDKhachHang FROM KhachHang WHERE HoTen = N'Nguyễn Auto Tùng' ORDER BY IDKhachHang DESC;

IF @KHID_DK IS NOT NULL
BEGIN
    EXEC sp_DangKyTheXeThang 
        @IDKhachHang = @KHID_DK, 
        @IDXe = '30A-888.88', 
        @IDBaiDo = 'BD001', 
        @TenTheXe = N'Thẻ Civic Tháng 11', 
        @SoThang = 1;
END
GO 
--------------------------GIA HẠN--------------------------------
PRINT N'--- 5.3 Thực hiện Gia hạn ---';
DECLARE @KHID_GH VARCHAR(12);
DECLARE @MaTheGiaHan VARCHAR(12);
DECLARE @MaBaiDo_Cu VARCHAR(8);
---------------TÌM THEO THẺ THEO TÊN KHÁCH HÀNG----------
SELECT TOP 1 @KHID_GH = IDKhachHang FROM KhachHang WHERE HoTen = N'Nguyễn Auto Tùng' ORDER BY IDKhachHang DESC;
-- Tìm thẻ mới nhất và bãi đỗ 
SELECT TOP 1 
    @MaTheGiaHan = IDTheThang,
    @MaBaiDo_Cu = 'BD001' 
FROM TheXeThang 
WHERE IDKhachHangNo = @KHID_GH 
ORDER BY NgayHetHan DESC;

IF @MaTheGiaHan IS NOT NULL
BEGIN
    PRINT N'-> Gia hạn thẻ: ' + @MaTheGiaHan + N' tại bãi: ' + @MaBaiDo_Cu;
    EXEC sp_GiaHanTheXeThang 
        @IDTheThang = @MaTheGiaHan, 
        @SoThang = 2, 
        @IDBaiDo = @MaBaiDo_Cu; 
END
GO
-------------HỦY THẺ----------------------------------------
PRINT N'--- 5.4 Thực hiện Hủy thẻ ---';
DECLARE @KHID_Huy VARCHAR(12);
DECLARE @MaTheHuy VARCHAR(12);

SELECT TOP 1 @KHID_Huy = IDKhachHang FROM KhachHang WHERE HoTen = N'Nguyễn Auto Tùng' ORDER BY IDKhachHang DESC;
SELECT TOP 1 @MaTheHuy = IDTheThang FROM TheXeThang WHERE IDKhachHangNo = @KHID_Huy ORDER BY NgayHetHan DESC;

IF @MaTheHuy IS NOT NULL
BEGIN
    EXEC sp_HuyTheXeThang @MaTheHuy;
    
    SELECT kh.HoTen AS [Khách Hàng], t.IDTheThang, t.NgayHetHan, 
           CASE t.TrangThai WHEN 1 THEN N'Hoạt động' ELSE N'Đã hủy' END AS [Trạng Thái]
    FROM TheXeThang t
    JOIN KhachHang kh ON t.IDKhachHangNo = kh.IDKhachHang
    WHERE t.IDTheThang = @MaTheHuy;
END
GO 
----------------------LỊCH SỬ GIAO DICH----------------------------
PRINT N'--- 6. Hóa đơn và Giao dịch ---';
SELECT 
    h.IDHoaDon, 
    kh.HoTen AS KhachHang,
    h.LoaiHoaDon, 
    h.ThanhTien, 
    ct.IDTheXeThangNo AS MaThe,
    tt.PhuongThuc,
    tt.TrangThai AS [1=DaThanhToan]
FROM HoaDon h
JOIN ChiTietHoaDon ct ON h.IDHoaDon = ct.IDHoaDonNo
JOIN TheXeThang t ON ct.IDTheXeThangNo = t.IDTheThang
JOIN KhachHang kh ON t.IDKhachHangNo = kh.IDKhachHang
JOIN ThanhToan tt ON h.IDHoaDon = tt.IDHoaDonNo
ORDER BY h.NgayTao DESC;
GO
------------------------------------------------------------
-- Bước 8: Test THỐNG KÊ TÌM KIẾM KHÁCH HÀNG
------------------------------------------------------------
-- 1. Thống kê cho khách hàng "Nguyễn Auto Tùng" (LỊCH SỬ GỬI XE CHI TIẾT VÀ PHƯƠNG THỨC THANH TOÁN)
PRINT N'--- THỐNG KÊ THEO TÊN KHÁCH HÀNG ---';
EXEC sp_ThongKeChiTietKhachHang @TuKhoa = N'Nguyễn Auto Tùng';

-- 3. Tra cứu lịch sử xe 
PRINT N'--- TRA CỨU LỊCH SỬ BIỂN SỐ XE ---';
EXEC sp_TraCuuLichSuXe @BienSo = '30A-888.88';
GO
------------------------------------------------------------
--BƯỚC 9: Test LỊCH LÀM VIỆC NHÂN VIÊN
------------------------------------------------------------
-- 1. Phân lịch cho Nguyễn Văn Bảo trực ca sáng tại Bãi xe Trung tâm trong 1 tuần
EXEC sp_PhanLichLamViec 
    @IDNhanVien = 'NV001_BV', 
    @IDCaLam = 'CL01_S', 
    @IDBaiDo = 'BD001', 
    @NgayBatDau = '2026-01-11', 
    @NgayKetThuc = '2026-01-17';

-- 2. Xem  ai đang trực tại Bãi xe Trung tâm (BD001) NGAY 12/1
EXEC sp_XemLichTrucChiTiet @NgayKiemTra = '2026-01-12', @IDBaiDo = 'BD001';
-- 3. Xem lịch trực của tất cả các bãi trong ngày hôm nay
EXEC sp_XemLichTrucChiTiet;