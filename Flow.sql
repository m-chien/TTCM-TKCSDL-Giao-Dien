
-- =============================================
-- Bước 1: Thêm tài khoản & Khách hàng
-- =============================================
PRINT N'--- 1. Thêm Tài khoản & Khách hàng ---';
EXEC sp_ThemTaiKhoanKhachHang 'tung_test_auto', '123', N'Nguyễn Auto Tùng', '0911222999', '123199999', N'Hà Nội';

-- Kiểm tra kết quả
SELECT TOP 1 * FROM KhachHang WHERE HoTen = N'Nguyễn Auto Tùng' ORDER BY IDKhachHang DESC;
-- Kiểm tra kết quả

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
	EXEC sp_ThemXeKhachHang @NewKHID_2, '30A-999.99', 'LX02_O4', 'Mazda3', 'Mazda', N'Trắng';
	EXEC sp_ThemXeKhachHang @NewKHID_2, '51K-123.45', 'LX02_O4', 'Camry', 'Toyota', N'Đen';

    -- Kiểm tra
	SELECT 
        x.BienSoXe, x.TenXe, x.Hang, x.MauSac, 
        kx.LoaiSoHuu, kh.HoTen
    FROM Xe x
    INNER JOIN KhachHang_Xe kx ON x.BienSoXe = kx.IDXeNo
    INNER JOIN KhachHang kh ON kx.IDKhachHangNo = kh.IDKhachHang
    WHERE kh.IDKhachHang = @NewKHID_2;
    SELECT * FROM KhachHang_Xe WHERE  IDKhachHangNo = @NewKHID_2;
END

--- xem bảng giá các bãi đỗ-----

SELECT 
    bd.TenBai,
    lx.TenLoaiXe,
    bg.TenBangGia,
    lh.TenLoaiHinh,
    lh.DonViThoiGian,
    lh.GiaTien,
    kg.TenKhungGio,
    kg.ThoiGianBatDau,
    kg.ThoiGianKetThuc
FROM BangGia bg
JOIN BaiDo bd ON bg.IDBaiDoNo = bd.IDBaiDo
JOIN LoaiXe lx ON bg.IDLoaiXeNo = lx.IDLoaiXe
JOIN LoaiHinhTinhPhi lh ON bg.IDBangGia = lh.IDBangGiaNo
LEFT JOIN KhungGio kg ON lh.IDLoaiHinhTinhPhi = kg.IDLoaiHinhTinhPhiNo
ORDER BY bd.IDBaiDo, lx.IDLoaiXe;

----------


-- =============================================
-- Bước 3: Khách hàng Đặt chỗ
-- =============================================
PRINT N'--- 3. Khách hàng Đặt chỗ ---';
BEGIN
    DECLARE @NewKHID_3 VARCHAR(12);
    SELECT TOP 1 @NewKHID_3 = IDKhachHang FROM KhachHang WHERE HoTen = N'Nguyễn Auto Tùng' ORDER BY IDKhachHang DESC;
    
    DECLARE @ChoDauTest VARCHAR(12) = 'CD0001_A';
    DECLARE @BienSoXeTest VARCHAR(20) = '30A-999.99';

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
	-- Bước 3.1: Khách hàng Đặt chỗ
	-- =============================================
	
------- TEST 1
-- =============================================
-- Bước 3.1: Khách hàng Đặt chỗ NHIỀU XE cùng lúc
-- (Cùng khung giờ - Khác chỗ đỗ) - Đã điều chỉnh hợp với sp_KhachHangDatCho
-- =============================================
PRINT N'================================================';
PRINT N'TEST: sp_DatChoVaThanhToanNhieuXe ';
PRINT N'================================================';
GO

SET NOCOUNT ON;

-- =====================================
-- 1. LẤY KHÁCH HÀNG
-- =====================================
DECLARE @KhachHangID VARCHAR(12);

SELECT TOP 1 @KhachHangID = IDKhachHang
FROM KhachHang
WHERE HoTen = N'Nguyễn Auto Tùng'
ORDER BY IDKhachHang DESC;

IF @KhachHangID IS NULL
BEGIN
    PRINT N'❌ Không tìm thấy khách hàng';
    RETURN;
END

PRINT N'✔ Khách hàng: ' + @KhachHangID;

-- =====================================
-- 2. DỮ LIỆU TEST (KHỚP SP)
-- =====================================
DECLARE @DanhSachXe  NVARCHAR(MAX) = '30A-999.99,51K-123.45';
DECLARE @DanhSachCho NVARCHAR(MAX) = 'CD0001_B,CD0002_B';

DECLARE @BatDau  DATETIME = DATEADD(DAY, 1, GETDATE());
DECLARE @KetThuc DATETIME = DATEADD(HOUR, 9, @BatDau);

DECLARE @PhuongThuc NVARCHAR(50) = N'Chuyển khoản';

PRINT N'✔ Thời gian: '
    + CONVERT(NVARCHAR, @BatDau, 120)
    + N' → '
    + CONVERT(NVARCHAR, @KetThuc, 120);

-- =====================================
-- 3. CHỌN VOUCHER HỢP LỆ
-- =====================================
DECLARE @MaVoucher NVARCHAR(20) = N'VC20K';

SELECT TOP 1 @MaVoucher = MaCode
FROM Voucher
WHERE TrangThai = 1
  AND SoLuong > 0
  AND HanSuDung >= CAST(GETDATE() AS DATE)
ORDER BY IDVoucher ASC;

IF @MaVoucher IS NOT NULL
    PRINT N'✔ Sử dụng voucher: ' + @MaVoucher;
ELSE
    PRINT N'⚠ Không có voucher hợp lệ, sẽ chạy không dùng voucher.';

-- =====================================
-- 4. RESET DATA CŨ (ĐÚNG THEO SP)
-- =====================================
PRINT N'→ Reset dữ liệu cũ';

BEGIN TRY
    BEGIN TRANSACTION;

    -- Xóa đặt chỗ theo các chỗ test
    DELETE FROM DatCho
    WHERE IDChoDauNo IN (
        SELECT TRIM(value)
        FROM STRING_SPLIT(@DanhSachCho, ',')
    );

    -- Xóa thanh toán
    DELETE TT
    FROM ThanhToan TT
    JOIN HoaDon HD ON TT.IDHoaDonNo = HD.IDHoaDon
    WHERE HD.LoaiHoaDon = N'Đặt chỗ';

    -- Xóa chi tiết hóa đơn
    DELETE CTHD
    FROM ChiTietHoaDon CTHD
    JOIN HoaDon HD ON CTHD.IDHoaDonNo = HD.IDHoaDon
    WHERE HD.LoaiHoaDon = N'Đặt chỗ';

    -- Xóa hóa đơn
    DELETE FROM HoaDon
    WHERE LoaiHoaDon = N'Đặt chỗ';

    COMMIT;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK;
    PRINT N'❌ RESET LỖI: ' + ERROR_MESSAGE();
    RETURN;
END CATCH

PRINT N'✔ Reset xong';

-- =====================================
-- 5. GỌI PROCEDURE
-- =====================================
PRINT N'→ Gọi sp_DatChoVaThanhToanNhieuXe';

EXEC sp_DatChoVaThanhToanNhieuXe
    @IDKhachHang  = @KhachHangID,
    @DanhSachXe   = @DanhSachXe,
    @DanhSachCho  = @DanhSachCho,
    @TgianBatDau  = @BatDau,
    @TgianKetThuc = @KetThuc,
    @PhuongThuc   = @PhuongThuc,
    @MaVoucher    = @MaVoucher; -- Truyền voucher vào SP

-- =====================================
-- 6. KIỂM TRA KẾT QUẢ
-- =====================================
PRINT N'--- ĐẶT CHỖ ---';
SELECT
    IDDatCho,
    IDXeNo       AS BienSoXe,
    IDChoDauNo,
    TgianBatDau,
    TgianKetThuc,
    TrangThai
FROM DatCho
WHERE IDKhachHangNo = @KhachHangID
ORDER BY IDDatCho;

PRINT N'--- HÓA ĐƠN ---';
SELECT *
FROM HoaDon
WHERE LoaiHoaDon = N'Đặt chỗ'
ORDER BY IDHoaDon DESC;

PRINT N'--- THANH TOÁN ---';
SELECT *
FROM ThanhToan
WHERE IDHoaDonNo IN (
    SELECT IDHoaDon
    FROM HoaDon
    WHERE LoaiHoaDon = N'Đặt chỗ'
)
ORDER BY IDThanhToan DESC;

PRINT N'--- CHI TIẾT HÓA ĐƠN ---';
SELECT *
FROM ChiTietHoaDon
WHERE IDHoaDonNo IN (
    SELECT IDHoaDon
    FROM HoaDon
    WHERE LoaiHoaDon = N'Đặt chỗ'
)
ORDER BY IDChiTietHoaDon;

PRINT N'✔ TEST HOÀN TẤT';
GO










------
EXEC sp_XemGiaDatCho 'CD0001_B', '30A-999.99', '2026-11-01 08:00', '2026-11-01 17:00';
EXEC sp_XemGiaDatCho 'CD0002_B', '51K-123.45', '2026-11-01 08:00', '2026-11-01 17:00';

-- =============================================
-- Bước 4: Nhân viên Duyệt đơn
-- =============================================
PRINT N'--- 4. Nhân viên Duyệt ---';
BEGIN
    -- Xem danh sách đơn đã thanh toán chờ nhân viên duyệt
    EXEC sp_DanhSachChoDuyet;

    DECLARE @NewKHID_4 VARCHAR(12);
    SELECT TOP 1 
        @NewKHID_4 = IDKhachHang
    FROM KhachHang
    WHERE HoTen = N'Nguyễn Auto Tùng'
    ORDER BY IDKhachHang DESC;

    -- Tìm đơn đặt chỗ đã thanh toán của khách này
    DECLARE @IDDonDat VARCHAR(20);

    SELECT TOP 1 
        @IDDonDat = IDDatCho
    FROM DatCho
    WHERE IDKhachHangNo = @NewKHID_4
      AND TrangThai = N'Đã thanh toán'   -- <-- chỉ duyệt những đơn đã thanh toán
    ORDER BY IDDatCho DESC;

    IF @IDDonDat IS NOT NULL
    BEGIN
        EXEC sp_NhanVienDuyetDatCho 
            @IDDatCho   = @IDDonDat,
            @IDNhanVien = 'NV001_BV',
            @TrangThaiMoi = N'Đã đặt';       -- Nhân viên duyệt: Đã đặt

        PRINT N'✔ Đã duyệt đơn: ' + @IDDonDat;
    END
    ELSE
        PRINT N'❌ Không tìm thấy đơn đã thanh toán nào.';

    -- =====================================
    -- Kiểm tra kết quả sau duyệt
    -- =====================================
    PRINT N'--- Trạng thái Đơn Đặt ---';
    SELECT 
        IDDatCho,
        TrangThai,
        IDNhanVienNo
    FROM DatCho
    WHERE IDDatCho = @IDDonDat;

    PRINT N'--- Trạng thái Chỗ Đậu ---';
    SELECT 
        cd.IDChoDauXe,
        cd.TenChoDau,
        cd.TrangThai
    FROM ChoDauXe cd
    JOIN DatCho dc ON dc.IDChoDauNo = cd.IDChoDauXe
    WHERE dc.IDDatCho = @IDDonDat;

END
GO



---NHÂN VIÊN DUYỆT CHO 2 ĐƠN ĐẶT CHỔ 
PRINT N'--- NHÂN VIÊN DUYỆT ĐƠN 1 ---';
EXEC sp_NhanVienDuyetDatCho 
    @IDDatCho   = 'DC0001_11012026', 
    @IDNhanVien = 'NV001_BV', 
    @TrangThaiMoi = N'Đã đặt';
PRINT N'✔ Đã duyệt đơn DC0001_11012026';

PRINT N'--- NHÂN VIÊN DUYỆT ĐƠN 2 ---';
EXEC sp_NhanVienDuyetDatCho 
    @IDDatCho   = 'DC0002_11012026', 
    @IDNhanVien = 'NV001_BV', 
    @TrangThaiMoi = N'Đã đặt';
PRINT N'✔ Đã duyệt đơn DC0002_11012026';




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


-- =============================================
-- Bước 7: Test Đăng ký thẻ tháng 
-- =============================================
PRINT N'--- 7. Test Thẻ tháng ---';
BEGIN
    DECLARE @NewKHID_7 VARCHAR(12);
    SELECT TOP 1 @NewKHID_7 = IDKhachHang FROM KhachHang WHERE HoTen = N'Nguyễn Auto Tùng' ORDER BY IDKhachHang DESC;
    
    EXEC sp_DangKyTheXeThang
        @IDKhachHang = @NewKHID_7,
        @IDXe = '30A-888.88',
	    @TenTheXe = N'Thẻ xe tháng Test',
        @SoThang = 1;

    -- Xem kết quả
    SELECT * FROM TheXeThang WHERE IDKhachHangNo = @NewKHID_7;
END



--- Đặt chổ nhiều xe 
