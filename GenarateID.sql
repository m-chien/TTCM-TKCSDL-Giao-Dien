USE ParkingLot;
GO

-- =============================================================
-- 1. BẢNG SINH MÃ TỰ ĐỘNG (BangSinhMa)
-- =============================================================
IF OBJECT_ID('BangSinhMa') IS NOT NULL DROP TABLE BangSinhMa;
GO
CREATE TABLE BangSinhMa (
    TenBang     VARCHAR(50) PRIMARY KEY,
    TienTo      VARCHAR(10),
    SoHienTai   INT NOT NULL
);
GO

-- Init Data
-- NOTE: Initial values set based on existing CITable.sql data to avoid conflicts
INSERT INTO BangSinhMa (TenBang, TienTo, SoHienTai) VALUES ('VaiTro', 'VT', 3);
INSERT INTO BangSinhMa (TenBang, TienTo, SoHienTai) VALUES ('LoaiXe', 'LX', 3);
INSERT INTO BangSinhMa (TenBang, TienTo, SoHienTai) VALUES ('CaLam', 'CL', 5);
INSERT INTO BangSinhMa (TenBang, TienTo, SoHienTai) VALUES ('TaiKhoan', 'TK', 3);
INSERT INTO BangSinhMa (TenBang, TienTo, SoHienTai) VALUES ('NhanVien', 'NV', 1);
INSERT INTO BangSinhMa (TenBang, TienTo, SoHienTai) VALUES ('KhachHang', 'KH', 1);
INSERT INTO BangSinhMa (TenBang, TienTo, SoHienTai) VALUES ('ChuBaiXe', 'CB', 1);
INSERT INTO BangSinhMa (TenBang, TienTo, SoHienTai) VALUES ('BaiDo', 'BD', 3);
INSERT INTO BangSinhMa (TenBang, TienTo, SoHienTai) VALUES ('KhuVuc', 'KV', 5);
INSERT INTO BangSinhMa (TenBang, TienTo, SoHienTai) VALUES ('ChoDauXe', 'CD', 1);
INSERT INTO BangSinhMa (TenBang, TienTo, SoHienTai) VALUES ('ThietBi', 'TB', 4);
INSERT INTO BangSinhMa (TenBang, TienTo, SoHienTai) VALUES ('BangGia', 'BG', 5);
INSERT INTO BangSinhMa (TenBang, TienTo, SoHienTai) VALUES ('LoaiHinhTinhPhi', 'LH', 7);
INSERT INTO BangSinhMa (TenBang, TienTo, SoHienTai) VALUES ('KhungGio', 'KG', 7);
INSERT INTO BangSinhMa (TenBang, TienTo, SoHienTai) VALUES ('TheXeThang', 'TXT', 1);
INSERT INTO BangSinhMa (TenBang, TienTo, SoHienTai) VALUES ('Voucher', 'VC', 2);
INSERT INTO BangSinhMa (TenBang, TienTo, SoHienTai) VALUES ('DatCho', 'DC', 1);
INSERT INTO BangSinhMa (TenBang, TienTo, SoHienTai) VALUES ('HoaDon', 'HD', 1);
INSERT INTO BangSinhMa (TenBang, TienTo, SoHienTai) VALUES ('PhieuGiuXe', 'PX', 1);
INSERT INTO BangSinhMa (TenBang, TienTo, SoHienTai) VALUES ('ChiTietHoaDon', 'CTHD', 1);
INSERT INTO BangSinhMa (TenBang, TienTo, SoHienTai) VALUES ('ThanhToan', 'TT', 1);
INSERT INTO BangSinhMa (TenBang, TienTo, SoHienTai) VALUES ('LichLamViec', 'LLV', 1);
INSERT INTO BangSinhMa (TenBang, TienTo, SoHienTai) VALUES ('SuCo', 'SC', 1);
INSERT INTO BangSinhMa (TenBang, TienTo, SoHienTai) VALUES ('DanhGia', 'DG', 1);
GO

-- =============================================================
-- 2. PROCEDURE SINH MÃ (sp_SinhMa) - Returns INT only
-- =============================================================
IF OBJECT_ID('sp_SinhMa') IS NOT NULL DROP PROCEDURE sp_SinhMa;
GO
CREATE PROCEDURE sp_SinhMa
    @TenBang VARCHAR(50),
    @SoMoi   INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @OutputTbl TABLE (So INT);

    UPDATE BangSinhMa WITH (UPDLOCK, HOLDLOCK)
    SET SoHienTai = SoHienTai + 1
    OUTPUT inserted.SoHienTai INTO @OutputTbl
    WHERE TenBang = @TenBang;

    SELECT @SoMoi = So FROM @OutputTbl;

    IF @SoMoi IS NULL
    BEGIN
        SET @SoMoi = 1;
        -- Insert default if not exists
        INSERT INTO BangSinhMa(TenBang, TienTo, SoHienTai) VALUES (@TenBang, '', 1);
    END
END;
GO

-- =============================================================
-- 3. CÁC PROCEDURE THÊM DỮ LIỆU (sp_Them...)
-- =============================================================

-- 1. VaiTro (VTxx_XX)
IF OBJECT_ID('sp_ThemVaiTro') IS NOT NULL DROP PROCEDURE sp_ThemVaiTro;
GO
CREATE PROCEDURE sp_ThemVaiTro
    @TenVaiTro NVARCHAR(50)
AS
BEGIN
    DECLARE @So INT, @NewID VARCHAR(10);
    EXEC sp_SinhMa 'VaiTro', @So OUTPUT;
    
    DECLARE @Suffix VARCHAR(3) = '_XX';
    IF @TenVaiTro LIKE N'%Nhân viên%' SET @Suffix = '_NV';
    ELSE IF @TenVaiTro LIKE N'%Khách hàng%' SET @Suffix = '_KH';
    ELSE IF @TenVaiTro LIKE N'%Chủ bãi%' SET @Suffix = '_CB';

    SET @NewID = 'VT' + RIGHT('00' + CAST(@So AS VARCHAR), 2) + @Suffix;
    
    INSERT INTO VaiTro(IDVaiTro, TenVaiTro) VALUES (@NewID, @TenVaiTro);
END;
GO

-- 2. LoaiXe (LXxx_XX)
IF OBJECT_ID('sp_ThemLoaiXe') IS NOT NULL DROP PROCEDURE sp_ThemLoaiXe;
GO
CREATE PROCEDURE sp_ThemLoaiXe
    @TenLoaiXe NVARCHAR(50)
AS
BEGIN
    DECLARE @So INT, @NewID VARCHAR(10);
    EXEC sp_SinhMa 'LoaiXe', @So OUTPUT;

    DECLARE @Suffix VARCHAR(3) = '_XX';
    IF @TenLoaiXe LIKE N'%4 chỗ%' SET @Suffix = '_O4';
    ELSE IF @TenLoaiXe LIKE N'%7 chỗ%' SET @Suffix = '_O7';

    SET @NewID = 'LX' + RIGHT('00' + CAST(@So AS VARCHAR), 2) + @Suffix;
    INSERT INTO LoaiXe(IDLoaiXe, TenLoaiXe) VALUES (@NewID, @TenLoaiXe);
END;
GO

-- 3. CaLam (CLxx_X)
IF OBJECT_ID('sp_ThemCaLam') IS NOT NULL DROP PROCEDURE sp_ThemCaLam;
GO
CREATE PROCEDURE sp_ThemCaLam
    @TenCa NVARCHAR(50), @TgianBatDau TIME, @TgianKetThuc TIME, @HeSoLuong FLOAT
AS
BEGIN
    DECLARE @So INT, @NewID VARCHAR(8);
    EXEC sp_SinhMa 'CaLam', @So OUTPUT;

    DECLARE @Suffix VARCHAR(3) = '_X';
    IF @TenCa LIKE N'%Sáng%' SET @Suffix = '_S';
    ELSE IF @TenCa LIKE N'%Chiều%' SET @Suffix = '_C';
    ELSE IF @TenCa LIKE N'%Đêm%' SET @Suffix = '_D';
    ELSE IF @TenCa LIKE N'%Hành chính%' SET @Suffix = '_HC';
    ELSE IF @TenCa LIKE N'%Tăng cường%' SET @Suffix = '_TC';

    SET @NewID = 'CL' + RIGHT('00' + CAST(@So AS VARCHAR), 2) + @Suffix;
    INSERT INTO CaLam(IDCaLam, TenCa, TgianBatDau, TgianKetThuc, HeSoLuong) 
    VALUES (@NewID, @TenCa, @TgianBatDau, @TgianKetThuc, @HeSoLuong);
END;
GO

-- 4. TaiKhoan (TKxxxxx_XX)
IF OBJECT_ID('sp_ThemTaiKhoan') IS NOT NULL DROP PROCEDURE sp_ThemTaiKhoan;
GO
CREATE PROCEDURE sp_ThemTaiKhoan
    @IDVaiTroNo VARCHAR(10), @TenDangNhap VARCHAR(50), @MatKhau VARCHAR(255), @AnhDaiDien VARCHAR(255)
AS
BEGIN
    DECLARE @So INT, @NewID VARCHAR(15);
    EXEC sp_SinhMa 'TaiKhoan', @So OUTPUT;

    DECLARE @Suffix VARCHAR(3) = '_KH';
    IF @IDVaiTroNo LIKE '%_NV' SET @Suffix = '_NV';
    ELSE IF @IDVaiTroNo LIKE '%_CB' SET @Suffix = '_CB';

    SET @NewID = 'TK' + RIGHT('00000' + CAST(@So AS VARCHAR), 5) + @Suffix;
    INSERT INTO TaiKhoan(IDTaiKhoan, IDVaiTroNo, TenDangNhap, MatKhau, AnhDaiDien, TrangThai) 
    VALUES (@NewID, @IDVaiTroNo, @TenDangNhap, @MatKhau, @AnhDaiDien, 1);
END;
GO

-- 5. NhanVien (NVxxx_XX)
IF OBJECT_ID('sp_ThemNhanVien') IS NOT NULL DROP PROCEDURE sp_ThemNhanVien;
GO
CREATE PROCEDURE sp_ThemNhanVien
    @IDTaiKhoanNo VARCHAR(15), @TenNhanVien NVARCHAR(100), @SDT VARCHAR(11), @Email VARCHAR(100), @ChucVu NVARCHAR(50), @LuongCB DECIMAL(18,2)
AS
BEGIN
    DECLARE @So INT, @NewID VARCHAR(10);
    EXEC sp_SinhMa 'NhanVien', @So OUTPUT;

    DECLARE @Suffix VARCHAR(3) = '_NV';
    IF @ChucVu LIKE N'%Bảo vệ%' SET @Suffix = '_BV';
    
    SET @NewID = 'NV' + RIGHT('000' + CAST(@So AS VARCHAR), 3) + @Suffix;
    INSERT INTO NhanVien(IDNhanVien, IDTaiKhoanNo, TenNhanVien, SDT, Email, ChucVu, LuongCB) 
    VALUES (@NewID, @IDTaiKhoanNo, @TenNhanVien, @SDT, @Email, @ChucVu, @LuongCB);
END;
GO

-- 6. KhachHang (KHxxxxx_XX)
IF OBJECT_ID('sp_ThemKhachHang') IS NOT NULL DROP PROCEDURE sp_ThemKhachHang;
GO
CREATE PROCEDURE sp_ThemKhachHang
    @IDTaiKhoanNo VARCHAR(15), @HoTen NVARCHAR(100), @SDT VARCHAR(11), @CCCD VARCHAR(20), @BangLaiXe VARCHAR(20), @DiaChi NVARCHAR(255), @LoaiKH NVARCHAR(50), @SoTK VARCHAR(20), @TenNganHang NVARCHAR(50)
AS
BEGIN
    DECLARE @So INT, @NewID VARCHAR(12);
    EXEC sp_SinhMa 'KhachHang', @So OUTPUT;
    
    DECLARE @Suffix VARCHAR(3);
    SET @Suffix = CASE @LoaiKH
            WHEN N'VIP' THEN '_VI'
            WHEN N'Thường xuyên' THEN '_TX'
            WHEN N'Vãng lai' THEN '_VL'
            ELSE '_KH'
          END;

    SET @NewID = 'KH' + RIGHT('00000' + CAST(@So AS VARCHAR), 5) + @Suffix;
    
    INSERT INTO KhachHang(IDKhachHang, IDTaiKhoanNo, HoTen, SDT, CCCD, BangLaiXe, DiaChi, LoaiKH, SoTK, TenNganHang) 
    VALUES (@NewID, @IDTaiKhoanNo, @HoTen, @SDT, @CCCD, @BangLaiXe, @DiaChi, @LoaiKH, @SoTK, @TenNganHang);
END;
GO

-- 7. ChuBaiXe (CBxxx)
IF OBJECT_ID('sp_ThemChuBaiXe') IS NOT NULL DROP PROCEDURE sp_ThemChuBaiXe;
GO
CREATE PROCEDURE sp_ThemChuBaiXe
    @IDTaiKhoanNo VARCHAR(15), @TenChuBai NVARCHAR(100), @SDT VARCHAR(11), @Email VARCHAR(100), @CCCD VARCHAR(20), @DiaChi NVARCHAR(255)
AS
BEGIN
    DECLARE @So INT, @NewID VARCHAR(8);
    EXEC sp_SinhMa 'ChuBaiXe', @So OUTPUT;
    
    SET @NewID = 'CB' + RIGHT('000' + CAST(@So AS VARCHAR), 3);
    INSERT INTO ChuBaiXe(IDChuBaiXe, IDTaiKhoanNo, TenChuBai, SDT, Email, CCCD, DiaChi) 
    VALUES (@NewID, @IDTaiKhoanNo, @TenChuBai, @SDT, @Email, @CCCD, @DiaChi);
END;
GO

-- 8. BaiDo (BDxxx)
IF OBJECT_ID('sp_ThemBaiDo') IS NOT NULL DROP PROCEDURE sp_ThemBaiDo;
GO
CREATE PROCEDURE sp_ThemBaiDo
    @IDChuBaiNo VARCHAR(8), @TenBai NVARCHAR(100), @ViTri NVARCHAR(255), @SucChua INT, @TrangThai NVARCHAR(50), @HinhAnh NVARCHAR(255)
AS
BEGIN
    DECLARE @So INT, @NewID VARCHAR(8);
    EXEC sp_SinhMa 'BaiDo', @So OUTPUT;
    
    SET @NewID = 'BD' + RIGHT('000' + CAST(@So AS VARCHAR), 3);
    INSERT INTO BaiDo(IDBaiDo, IDChuBaiNo, TenBai, ViTri, SucChua, TrangThai, HinhAnh) 
    VALUES (@NewID, @IDChuBaiNo, @TenBai, @ViTri, @SucChua, @TrangThai, @HinhAnh);
END;
GO

-- 9. KhuVuc (KVxxx_X)
IF OBJECT_ID('sp_ThemKhuVuc') IS NOT NULL DROP PROCEDURE sp_ThemKhuVuc;
GO
CREATE PROCEDURE sp_ThemKhuVuc
    @IDBaiDoNo VARCHAR(8), @TenKhuVuc NVARCHAR(50), @SucChua INT, @HinhAnh VARCHAR(255)
AS
BEGIN
    DECLARE @So INT, @NewID VARCHAR(10);
    EXEC sp_SinhMa 'KhuVuc', @So OUTPUT;

    -- Infer suffix from TenKhuVuc (e.g., 'Khu A' -> '_A')
    DECLARE @Suffix VARCHAR(5) = '_X';
    IF @TenKhuVuc LIKE N'Khu %' 
        SET @Suffix = '_' + SUBSTRING(@TenKhuVuc, CHARINDEX(' ', @TenKhuVuc) + 1, 1);
    
    SET @NewID = 'KV' + RIGHT('000' + CAST(@So AS VARCHAR), 3) + @Suffix;
    INSERT INTO KhuVuc(IDKhuVuc, IDBaiDoNo, TenKhuVuc, SucChua, HinhAnh) 
    VALUES (@NewID, @IDBaiDoNo, @TenKhuVuc, @SucChua, @HinhAnh);
END;
GO

-- 10. ChoDauXe (CDxxxx_X)
IF OBJECT_ID('sp_ThemChoDauXe') IS NOT NULL DROP PROCEDURE sp_ThemChoDauXe;
GO
CREATE PROCEDURE sp_ThemChoDauXe
    @IDKhuVucNo VARCHAR(10), @TenChoDau NVARCHAR(20), @KichThuoc VARCHAR(50), @TrangThai NVARCHAR(50)
AS
BEGIN
    DECLARE @So INT, @NewID VARCHAR(12);
    EXEC sp_SinhMa 'ChoDauXe', @So OUTPUT;

    -- Suffix from KhuVuc? KV001_A -> _A
    DECLARE @Suffix VARCHAR(5) = '_X';
    IF CHARINDEX('_', @IDKhuVucNo) > 0
        SET @Suffix = SUBSTRING(@IDKhuVucNo, CHARINDEX('_', @IDKhuVucNo), LEN(@IDKhuVucNo));
    
    SET @NewID = 'CD' + RIGHT('0000' + CAST(@So AS VARCHAR), 4) + @Suffix;
    INSERT INTO ChoDauXe(IDChoDauXe, IDKhuVucNo, TenChoDau, KichThuoc, TrangThai) 
    VALUES (@NewID, @IDKhuVucNo, @TenChoDau, @KichThuoc, @TrangThai);
END;
GO

-- 11. ThietBi (TBxxx_XX)
IF OBJECT_ID('sp_ThemThietBi') IS NOT NULL DROP PROCEDURE sp_ThemThietBi;
GO
CREATE PROCEDURE sp_ThemThietBi
    @IDKhuVucNo VARCHAR(10), @TenThietBi NVARCHAR(100), @LoaiThietBi NVARCHAR(50), @TrangThai NVARCHAR(50), @NgayCaiDat DATE, @GiaLapDat DECIMAL(18,2)
AS
BEGIN
    DECLARE @So INT, @NewID VARCHAR(10);
    EXEC sp_SinhMa 'ThietBi', @So OUTPUT;

    DECLARE @Suffix VARCHAR(3) = '_XX';
    IF @TenThietBi LIKE N'%Camera%' OR @LoaiThietBi LIKE N'%Camera%' SET @Suffix = '_CA';
    ELSE IF @TenThietBi LIKE N'%Barrier%' OR @LoaiThietBi LIKE N'%Cổng%' SET @Suffix = '_CB';
    ELSE IF @TenThietBi LIKE N'%Phần mềm%' SET @Suffix = '_PM';

    SET @NewID = 'TB' + RIGHT('000' + CAST(@So AS VARCHAR), 3) + @Suffix;
    INSERT INTO ThietBi(IDThietBi, IDKhuVucNo, TenThietBi, LoaiThietBi, TrangThai, NgayCaiDat, GiaLapDat) 
    VALUES (@NewID, @IDKhuVucNo, @TenThietBi, @LoaiThietBi, @TrangThai, @NgayCaiDat, @GiaLapDat);
END;
GO

-- 12. BangGia (BGxxx_XX)
IF OBJECT_ID('sp_ThemBangGia') IS NOT NULL DROP PROCEDURE sp_ThemBangGia;
GO
CREATE PROCEDURE sp_ThemBangGia
    @IDBaiDoNo VARCHAR(8), @IDLoaiXeNo VARCHAR(10), @TenBangGia NVARCHAR(100), @HieuLuc BIT
AS
BEGIN
    DECLARE @So INT, @NewID VARCHAR(10);
    EXEC sp_SinhMa 'BangGia', @So OUTPUT;

    -- Suffix from LoaiXe: LX01_XM -> _XM
    DECLARE @Suffix VARCHAR(5) = '_XX';
    IF CHARINDEX('_', @IDLoaiXeNo) > 0
        SET @Suffix = SUBSTRING(@IDLoaiXeNo, CHARINDEX('_', @IDLoaiXeNo), LEN(@IDLoaiXeNo));

    SET @NewID = 'BG' + RIGHT('000' + CAST(@So AS VARCHAR), 3) + @Suffix;
    INSERT INTO BangGia(IDBangGia, IDBaiDoNo, IDLoaiXeNo, TenBangGia, HieuLuc) 
    VALUES (@NewID, @IDBaiDoNo, @IDLoaiXeNo, @TenBangGia, @HieuLuc);
END;
GO

-- 13. LoaiHinhTinhPhi (LHxxx_XXXX_XX)
IF OBJECT_ID('sp_ThemLoaiHinhTinhPhi') IS NOT NULL DROP PROCEDURE sp_ThemLoaiHinhTinhPhi;
GO
CREATE PROCEDURE sp_ThemLoaiHinhTinhPhi
    @IDBangGiaNo VARCHAR(10), @TenLoaiHinh NVARCHAR(100), @DonViThoiGian NVARCHAR(50), @GiaTien DECIMAL(18,2)
AS
BEGIN
    DECLARE @So INT, @NewID VARCHAR(15);
    EXEC sp_SinhMa 'LoaiHinhTinhPhi', @So OUTPUT;
    
    -- Suffix: _GIO_O4 etc.
    -- Derive from TenLoaiHinh and BangGia?
    DECLARE @S1 VARCHAR(5) = 'XXX';
    IF @DonViThoiGian = N'Giờ' SET @S1 = 'GIO';
    ELSE IF @DonViThoiGian = N'Ngày' SET @S1 = 'NGAY';
    ELSE IF @DonViThoiGian = N'Tháng' SET @S1 = 'THANG';
    
    DECLARE @S2 VARCHAR(5) = 'XX';
    -- Extract from IDBangGia? BG001_O4 -> O4
    IF CHARINDEX('_', @IDBangGiaNo) > 0
        SET @S2 = SUBSTRING(@IDBangGiaNo, CHARINDEX('_', @IDBangGiaNo)+1, LEN(@IDBangGiaNo));
        
    SET @NewID = 'LH' + RIGHT('000' + CAST(@So AS VARCHAR), 3) + '_' + @S1 + '_' + @S2;
    INSERT INTO LoaiHinhTinhPhi(IDLoaiHinhTinhPhi, IDBangGiaNo, TenLoaiHinh, DonViThoiGian, GiaTien) 
    VALUES (@NewID, @IDBangGiaNo, @TenLoaiHinh, @DonViThoiGian, @GiaTien);
END;
GO

-- 14. KhungGio (KGxx_XX)
IF OBJECT_ID('sp_ThemKhungGio') IS NOT NULL DROP PROCEDURE sp_ThemKhungGio;
GO
CREATE PROCEDURE sp_ThemKhungGio
    @IDLoaiHinhTinhPhiNo VARCHAR(15), @TenKhungGio NVARCHAR(50), @ThoiGianBatDau TIME, @ThoiGianKetThuc TIME
AS
BEGIN
    DECLARE @So INT, @NewID VARCHAR(10);
    EXEC sp_SinhMa 'KhungGio', @So OUTPUT;

    DECLARE @Suffix VARCHAR(3) = '_XX';
    IF @TenKhungGio LIKE N'%Hành chính%' SET @Suffix = '_HC';
    ELSE IF @TenKhungGio LIKE N'%Ban ngày%' SET @Suffix = '_GN';
    ELSE IF @TenKhungGio LIKE N'%Ban đêm%' SET @Suffix = '_GD';
    ELSE IF @TenKhungGio LIKE N'%ấp điểm%' SET @Suffix = '_TC'; -- Thap diem/Tang cuong

    SET @NewID = 'KG' + RIGHT('00' + CAST(@So AS VARCHAR), 2) + @Suffix;
    INSERT INTO KhungGio(IDKhungGio, IDLoaiHinhTinhPhiNo, TenKhungGio, ThoiGianBatDau, ThoiGianKetThuc) 
    VALUES (@NewID, @IDLoaiHinhTinhPhiNo, @TenKhungGio, @ThoiGianBatDau, @ThoiGianKetThuc);
END;
GO

-- 15. TheXeThang (TXTxxx_xxT)
IF OBJECT_ID('sp_ThemTheXeThang') IS NOT NULL DROP PROCEDURE sp_ThemTheXeThang;
GO
CREATE PROCEDURE sp_ThemTheXeThang
    @IDKhachHangNo VARCHAR(12), @IDXeNo VARCHAR(12), @TenTheXe NVARCHAR(100), @NgayDangKy DATE, @NgayHetHan DATE
AS
BEGIN
    DECLARE @So INT, @NewID VARCHAR(12);
    EXEC sp_SinhMa 'TheXeThang', @So OUTPUT;

    -- Infer months?? Or just hardcode suffix like samples?
    -- Sample TXT001_12T. Derived from NgayHetHan - NgayDangKy?
    DECLARE @Months INT = DATEDIFF(MONTH, @NgayDangKy, @NgayHetHan);
    IF @Months < 1 SET @Months = 1;
    
    SET @NewID = 'TXT' + RIGHT('000' + CAST(@So AS VARCHAR), 3) + '_' + CAST(@Months AS VARCHAR) + 'T';
    INSERT INTO TheXeThang(IDTheThang, IDKhachHangNo, IDXeNo, TenTheXe, NgayDangKy, NgayHetHan, TrangThai) 
    VALUES (@NewID, @IDKhachHangNo, @IDXeNo, @TenTheXe, @NgayDangKy, @NgayHetHan, 1);
END;
GO

-- 16. Voucher (VCxxxxx_BDxxx)
IF OBJECT_ID('sp_ThemVoucher') IS NOT NULL DROP PROCEDURE sp_ThemVoucher;
GO
CREATE PROCEDURE sp_ThemVoucher
    @IDBaiDoNo VARCHAR(8), @TenVoucher NVARCHAR(100), @GiaTri DECIMAL(18,2), @HanSuDung DATE, @SoLuong INT, @MaCode VARCHAR(20)
AS
BEGIN
    DECLARE @So INT, @NewID VARCHAR(15);
    EXEC sp_SinhMa 'Voucher', @So OUTPUT;
    
    SET @NewID = 'VC' + RIGHT('00000' + CAST(@So AS VARCHAR), 5) + '_' + @IDBaiDoNo;
    INSERT INTO Voucher(IDVoucher, IDBaiDoNo, TenVoucher, GiaTri, HanSuDung, SoLuong, TrangThai, MaCode) 
    VALUES (@NewID, @IDBaiDoNo, @TenVoucher, @GiaTri, @HanSuDung, @SoLuong, 1, @MaCode);
END;
GO

-- 17. DatCho (DCxxxx_ddMMyyyy)
IF OBJECT_ID('sp_ThemDatCho') IS NOT NULL DROP PROCEDURE sp_ThemDatCho;
GO
CREATE PROCEDURE sp_ThemDatCho
    @IDKhachHangNo VARCHAR(12), @IDXeNo VARCHAR(12), @IDChoDauNo VARCHAR(12), @IDNhanVienNo VARCHAR(10), @TgianBatDau DATETIME, @TgianKetThuc DATETIME
AS
BEGIN
    DECLARE @So INT, @NewID VARCHAR(20);
    EXEC sp_SinhMa 'DatCho', @So OUTPUT;

    DECLARE @DateStr VARCHAR(10) = REPLACE(CONVERT(VARCHAR, GETDATE(), 103), '/', '');
    SET @NewID = 'DC' + RIGHT('0000' + CAST(@So AS VARCHAR), 4) + '_' + @DateStr;
    
    INSERT INTO DatCho(IDDatCho, IDKhachHangNo, IDXeNo, IDChoDauNo, IDNhanVienNo, TgianBatDau, TgianKetThuc, TrangThai) 
    VALUES (@NewID, @IDKhachHangNo, @IDXeNo, @IDChoDauNo, @IDNhanVienNo, @TgianBatDau, @TgianKetThuc, N'Đang chờ duyệt');
END;
GO

-- 18. HoaDon (HDxxxx_ddMMyyyy)
IF OBJECT_ID('sp_ThemHoaDon') IS NOT NULL DROP PROCEDURE sp_ThemHoaDon;
GO
CREATE PROCEDURE sp_ThemHoaDon
    @ThanhTien DECIMAL(18,2), @LoaiHoaDon NVARCHAR(50), @IDVoucher VARCHAR(15)
AS
BEGIN
    DECLARE @So INT, @NewID VARCHAR(20);
    EXEC sp_SinhMa 'HoaDon', @So OUTPUT;
    
    DECLARE @DateStr VARCHAR(10) = REPLACE(CONVERT(VARCHAR, GETDATE(), 103), '/', '');
    SET @NewID = 'HD' + RIGHT('0000' + CAST(@So AS VARCHAR), 4) + '_' + @DateStr;

    INSERT INTO HoaDon(IDHoaDon, ThanhTien, NgayTao, LoaiHoaDon, IDVoucher) 
    VALUES (@NewID, @ThanhTien, GETDATE(), @LoaiHoaDon, @IDVoucher);
END;
GO

-- 19. PhieuGiuXe (PXxxxx_Axxxx)
IF OBJECT_ID('sp_ThemPhieuGiuXe') IS NOT NULL DROP PROCEDURE sp_ThemPhieuGiuXe;
GO
CREATE PROCEDURE sp_ThemPhieuGiuXe
    @IDKhachHangNo VARCHAR(12), @IDXeNo VARCHAR(12), @IDChoDauNo VARCHAR(12), @IDNhanVienVao VARCHAR(10)
AS
BEGIN
    DECLARE @So INT, @NewID VARCHAR(15);
    EXEC sp_SinhMa 'PhieuGiuXe', @So OUTPUT;
    
    -- Suffix: CD0001_A -> _A0001?
    -- Sample: PX0001_A0001. 
    -- Logic: PX + count + _ + SuffixFromChoDao(A) + NumberFromChoDau(0001)?
    -- Let's extract 'A' and '0001' from CD0001_A
    DECLARE @ChoSuffix VARCHAR(10) = '';
    DECLARE @ChoNum VARCHAR(10) = '';
    
    IF CHARINDEX('_', @IDChoDauNo) > 0
    BEGIN
        SET @ChoSuffix = SUBSTRING(@IDChoDauNo, CHARINDEX('_', @IDChoDauNo)+1, LEN(@IDChoDauNo)); -- 'A'
        -- CD0001_A. Number is chars 3 to len-2?
        SET @ChoNum = SUBSTRING(@IDChoDauNo, 3, CHARINDEX('_', @IDChoDauNo)-3); -- '0001'
    END

    SET @NewID = 'PX' + RIGHT('0000' + CAST(@So AS VARCHAR), 4) + '_' + @ChoSuffix + @ChoNum;
    
    INSERT INTO PhieuGiuXe(IDPhieuGiuXe, IDKhachHangNo, IDXeNo, IDChoDauNo, IDNhanVienVao, TgianVao, TrangThai) 
    VALUES (@NewID, @IDKhachHangNo, @IDXeNo, @IDChoDauNo, @IDNhanVienVao, GETDATE(), N'Đang gửi');
END;
GO

-- 20. ChiTietHoaDon (CTHDxxxx_HDxxxx)
IF OBJECT_ID('sp_ThemChiTietHoaDon') IS NOT NULL DROP PROCEDURE sp_ThemChiTietHoaDon;
GO
CREATE PROCEDURE sp_ThemChiTietHoaDon
    @IDTheXeThangNo VARCHAR(12), @IDDatChoNo VARCHAR(20), @IDHoaDonNo VARCHAR(20), @TongTien DECIMAL(18,2)
AS
BEGIN
    DECLARE @So INT, @NewID VARCHAR(20);
    EXEC sp_SinhMa 'ChiTietHoaDon', @So OUTPUT;
    
    -- Suffix _HDxxxx_Date
    -- IDHoaDon: HD0001_05012026. Keep it simple or use just the HD prefix?
    -- Sample: CTHD0001_HD0001. So just the first part of IDHoaDon?
    DECLARE @HDSuffix VARCHAR(20) = @IDHoaDonNo;
    IF CHARINDEX('_', @IDHoaDonNo) > 0 
       SET @HDSuffix = SUBSTRING(@IDHoaDonNo, 1, CHARINDEX('_', @IDHoaDonNo)-1);

    SET @NewID = 'CTHD' + RIGHT('0000' + CAST(@So AS VARCHAR), 4) + '_' + @HDSuffix;
    
    INSERT INTO ChiTietHoaDon(IDChiTietHoaDon, IDTheXeThangNo, IDDatChoNo, IDHoaDonNo, TongTien) 
    VALUES (@NewID, @IDTheXeThangNo, @IDDatChoNo, @IDHoaDonNo, @TongTien);
END;
GO

-- 21. ThanhToan (TTxxxxx_XX)
IF OBJECT_ID('sp_ThemThanhToan') IS NOT NULL DROP PROCEDURE sp_ThemThanhToan;
GO
CREATE PROCEDURE sp_ThemThanhToan
    @IDHoaDonNo VARCHAR(20), @PhuongThuc NVARCHAR(50)
AS
BEGIN
    DECLARE @So INT, @NewID VARCHAR(12);
    EXEC sp_SinhMa 'ThanhToan', @So OUTPUT;
    
    DECLARE @Suffix VARCHAR(3) = '_TM';
    IF @PhuongThuc LIKE N'%Chuyển khoản%' SET @Suffix = '_CK';
    ELSE IF @PhuongThuc LIKE N'%Thẻ%' SET @Suffix = '_TH';
    ELSE IF @PhuongThuc LIKE N'%QR%' SET @Suffix = '_QR';

    SET @NewID = 'TT' + RIGHT('00000' + CAST(@So AS VARCHAR), 5) + @Suffix;
    INSERT INTO ThanhToan(IDThanhToan, IDHoaDonNo, PhuongThuc, TrangThai, NgayThanhToan) 
    VALUES (@NewID, @IDHoaDonNo, @PhuongThuc, 0, GETDATE());
END;
GO

-- 22. LichLamViec (LLVxxxxx_NVxxx)
IF OBJECT_ID('sp_ThemLichLamViec') IS NOT NULL DROP PROCEDURE sp_ThemLichLamViec;
GO
CREATE PROCEDURE sp_ThemLichLamViec
    @IDNhanVienNo VARCHAR(10), @IDCaLamNo VARCHAR(8), @IDBaiDoNo VARCHAR(8), @NgayBatDau DATE, @NgayKetThuc DATE
AS
BEGIN
    DECLARE @So INT, @NewID VARCHAR(15);
    EXEC sp_SinhMa 'LichLamViec', @So OUTPUT;
    
    -- Suffix: NV001_BV -> _001?
    DECLARE @NVSuffix VARCHAR(5) = '001';
    IF LEN(@IDNhanVienNo) >= 5
        SET @NVSuffix = SUBSTRING(@IDNhanVienNo, 3, 3);
        
    SET @NewID = 'LLV' + RIGHT('00000' + CAST(@So AS VARCHAR), 5) + '_' + @NVSuffix;
    INSERT INTO LichLamViec(IDLichLamViec, IDNhanVienNo, IDCaLamNo, IDBaiDoNo, NgayBatDau, NgayKetThuc, TrangThai, SoNgayDaLam) 
    VALUES (@NewID, @IDNhanVienNo, @IDCaLamNo, @IDBaiDoNo, @NgayBatDau, @NgayKetThuc, 0, 0);
END;
GO

-- 23. SuCo (SCxxx_XX)
IF OBJECT_ID('sp_ThemSuCo') IS NOT NULL DROP PROCEDURE sp_ThemSuCo;
GO
CREATE PROCEDURE sp_ThemSuCo
    @IDNhanVienNo VARCHAR(10), @IDThietBiNo VARCHAR(10), @MoTa NVARCHAR(MAX), @MucDo NVARCHAR(50)
AS
BEGIN
    DECLARE @So INT, @NewID VARCHAR(10);
    EXEC sp_SinhMa 'SuCo', @So OUTPUT;

    -- Suffix from ThietBi type? TB001_CA -> _CA
    DECLARE @Suffix VARCHAR(5) = '_XX';
    IF CHARINDEX('_', @IDThietBiNo) > 0
        SET @Suffix = SUBSTRING(@IDThietBiNo, CHARINDEX('_', @IDThietBiNo), LEN(@IDThietBiNo));
        
    SET @NewID = 'SC' + RIGHT('000' + CAST(@So AS VARCHAR), 3) + @Suffix;
    INSERT INTO SuCo(IDSuCo, IDNhanVienNo, IDThietBiNo, MoTa, MucDo, TrangThaiXuLy) 
    VALUES (@NewID, @IDNhanVienNo, @IDThietBiNo, @MoTa, @MucDo, N'Chưa xử lý');
END;
GO

-- 24. DanhGia (DGxxx_KHxxxx)
IF OBJECT_ID('sp_ThemDanhGia') IS NOT NULL DROP PROCEDURE sp_ThemDanhGia;
GO
CREATE PROCEDURE sp_ThemDanhGia
    @IDKhachHangNo VARCHAR(12), @IDHoaDonNo VARCHAR(20), @NoiDung NVARCHAR(MAX), @DiemDanhGia INT
AS
BEGIN
    DECLARE @So INT, @NewID VARCHAR(12);
    EXEC sp_SinhMa 'DanhGia', @So OUTPUT;
    
    -- Suffix: KH00001_VI -> _0001
    DECLARE @KHSuffix VARCHAR(5) = '0000';
    IF LEN(@IDKhachHangNo) >= 7
        SET @KHSuffix = SUBSTRING(@IDKhachHangNo, 3, 4);

    SET @NewID = 'DG' + RIGHT('000' + CAST(@So AS VARCHAR), 3) + '_' + @KHSuffix;
    INSERT INTO DanhGia(IDDanhGia, IDKhachHangNo, IDHoaDonNo, NoiDung, DiemDanhGia, NgayDanhGia) 
    VALUES (@NewID, @IDKhachHangNo, @IDHoaDonNo, @NoiDung, @DiemDanhGia, GETDATE());
END;
GO
