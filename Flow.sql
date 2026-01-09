
-- =============================================
-- Bước 1: Thêm tài khoản & Khách hàng
-- =============================================
PRINT N'--- 1. Thêm Tài khoản & Khách hàng ---';
EXEC sp_ThemTaiKhoanKhachHang 'tung_test_auto', '123', N'Nguyễn Auto Tùng', '0911222999', '123199999', N'Hà Nội';

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