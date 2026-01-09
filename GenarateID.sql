USE ParkingLot;
GO

-- =============================================================
-- TRIGGER TỰ ĐỘNG SINH ID CHO CÁC BẢNG (AUTO GENERATE ID)
-- Lưu ý: Sử dụng INSTEAD OF INSERT vì ID là Primary Key không được phép NULL
-- Logoc: Tìm Max ID hiện tại -> Tách số -> +1 -> Format lại string
-- =============================================================

-- 1. Bảng TaiKhoan (TKxxxxx_XX)
IF OBJECT_ID('trg_AutoID_TaiKhoan') IS NOT NULL DROP TRIGGER trg_AutoID_TaiKhoan;
GO
CREATE TRIGGER trg_AutoID_TaiKhoan ON TaiKhoan INSTEAD OF INSERT AS 
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @RowID INT, @IDVaiTro VARCHAR(10), @TenDangNhap VARCHAR(50), @MatKhau VARCHAR(255), @Anh VARCHAR(255), @TT BIT;
    
    -- Xử lý từng dòng (Cursor hoặc Loop nếu insert nhiều, ở đây demo cho single/batch nhỏ)
    -- Để đơn giản và an toàn, dùng Cursor cho Inserted
    DECLARE cur CURSOR FOR SELECT IDVaiTroNo, TenDangNhap, MatKhau, AnhDaiDien, TrangThai FROM inserted;
    OPEN cur;
    FETCH NEXT FROM cur INTO @IDVaiTro, @TenDangNhap, @MatKhau, @Anh, @TT;
    
    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Sinh ID
        DECLARE @Suffix VARCHAR(5) = '_KH'; -- Default
        IF @IDVaiTro = 'VT01_NV' SET @Suffix = '_NV';
        ELSE IF @IDVaiTro = 'VT03_CB' SET @Suffix = '_CB';
        
        DECLARE @MaxID VARCHAR(15);
        DECLARE @NextNum INT;
        SELECT @MaxID = MAX(IDTaiKhoan) FROM TaiKhoan WHERE IDTaiKhoan LIKE 'TK%' + @Suffix;
        
        IF @MaxID IS NULL SET @NextNum = 1;
        ELSE 
            -- TK00001_KH -> Substring(3, 5)
            SET @NextNum = CAST(SUBSTRING(@MaxID, 3, 5) AS INT) + 1;
            
        DECLARE @NewID VARCHAR(15) = 'TK' + RIGHT('00000' + CAST(@NextNum AS VARCHAR), 5) + @Suffix;
        
        -- Insert Thật
        INSERT INTO TaiKhoan (IDTaiKhoan, IDVaiTroNo, TenDangNhap, MatKhau, AnhDaiDien, TrangThai)
        VALUES (@NewID, @IDVaiTro, @TenDangNhap, @MatKhau, @Anh, ISNULL(@TT, 1));
        
        FETCH NEXT FROM cur INTO @IDVaiTro, @TenDangNhap, @MatKhau, @Anh, @TT;
    END
    CLOSE cur; DEALLOCATE cur;
END;
GO

-- 2. Bảng NhanVien (NVxxx_XX)
IF OBJECT_ID('trg_AutoID_NhanVien') IS NOT NULL DROP TRIGGER trg_AutoID_NhanVien;
GO
CREATE TRIGGER trg_AutoID_NhanVien ON NhanVien INSTEAD OF INSERT AS 
BEGIN
    SET NOCOUNT ON;
    DECLARE cur CURSOR FOR SELECT IDTaiKhoanNo, TenNhanVien, SDT, Email, ChucVu, LuongCB FROM inserted;
    
    DECLARE @IDTK VARCHAR(15), @Ten NVARCHAR(100), @SDT VARCHAR(11), @Email VARCHAR(100), @CV NVARCHAR(50), @Luong DECIMAL(18,2);
    OPEN cur;
    FETCH NEXT FROM cur INTO @IDTK, @Ten, @SDT, @Email, @CV, @Luong;
    
    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Format NV001_BV. Suffix based on ChucVu? Let's take first letter words.
        -- Simple: NV + 3 digits + _BV (Default)
        DECLARE @Suffix VARCHAR(5) = '_NV';
        IF @CV LIKE N'%Bảo vệ%' SET @Suffix = '_BV';
        
        DECLARE @MaxID VARCHAR(15);
        DECLARE @NextNum INT;
        SELECT @MaxID = MAX(IDNhanVien) FROM NhanVien WHERE IDNhanVien LIKE 'NV%' + @Suffix;
        
        IF @MaxID IS NULL SET @NextNum = 1;
        ELSE SET @NextNum = CAST(SUBSTRING(@MaxID, 3, 3) AS INT) + 1;
            
        DECLARE @NewID VARCHAR(15) = 'NV' + RIGHT('000' + CAST(@NextNum AS VARCHAR), 3) + @Suffix;
        
        INSERT INTO NhanVien (IDNhanVien, IDTaiKhoanNo, TenNhanVien, SDT, Email, ChucVu, LuongCB)
        VALUES (@NewID, @IDTK, @Ten, @SDT, @Email, @CV, @Luong);
        
        FETCH NEXT FROM cur INTO @IDTK, @Ten, @SDT, @Email, @CV, @Luong;
    END
    CLOSE cur; DEALLOCATE cur;
END;
GO

-- 3. Bảng KhachHang (KHxxxxx_XX)
IF OBJECT_ID('trg_AutoID_KhachHang') IS NOT NULL DROP TRIGGER trg_AutoID_KhachHang;
GO
CREATE TRIGGER trg_AutoID_KhachHang ON KhachHang INSTEAD OF INSERT AS
BEGIN
    SET NOCOUNT ON;
    -- Note: Trigger này thay thế logic Insert thủ công trong SP
    
    INSERT INTO KhachHang (IDKhachHang, IDTaiKhoanNo, HoTen, SDT, CCCD, BangLaiXe, DiaChi, LoaiKH, SoTK, TenNganHang)
    SELECT 
        'KH' + RIGHT('00000' + CAST(
            ISNULL((SELECT MAX(CAST(SUBSTRING(IDKhachHang, 3, 5) AS INT)) FROM KhachHang WHERE IDKhachHang LIKE 'KH%_TX'), 0) 
            + ROW_NUMBER() OVER(ORDER BY (SELECT 1)) 
        AS VARCHAR), 5) + '_TX', -- Mặc định suffix TX cho auto
        IDTaiKhoanNo, HoTen, SDT, CCCD, BangLaiXe, DiaChi, LoaiKH, SoTK, TenNganHang
    FROM inserted;
END;
GO

-- 4. Bảng BaiDo (BDxxx)
IF OBJECT_ID('trg_AutoID_BaiDo') IS NOT NULL DROP TRIGGER trg_AutoID_BaiDo;
GO
CREATE TRIGGER trg_AutoID_BaiDo ON BaiDo INSTEAD OF INSERT AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO BaiDo (IDBaiDo, IDChuBaiNo, TenBai, ViTri, SucChua, TrangThai, HinhAnh)
    SELECT 
        'BD' + RIGHT('000' + CAST(
            ISNULL((SELECT MAX(CAST(SUBSTRING(IDBaiDo, 3, 3) AS INT)) FROM BaiDo), 0) 
            + ROW_NUMBER() OVER(ORDER BY (SELECT 1)) 
        AS VARCHAR), 3),
        IDChuBaiNo, TenBai, ViTri, SucChua, TrangThai, HinhAnh
    FROM inserted;
END;
GO
    
-- 5. Bảng ChoDauXe (CDxxxx_X) - Suffix khó đoán, mặc định _A
IF OBJECT_ID('trg_AutoID_ChoDauXe') IS NOT NULL DROP TRIGGER trg_AutoID_ChoDauXe;
GO
CREATE TRIGGER trg_AutoID_ChoDauXe ON ChoDauXe INSTEAD OF INSERT AS
BEGIN
    SET NOCOUNT ON;
    -- CD0001_A
    INSERT INTO ChoDauXe (IDChoDauXe, IDKhuVucNo, TenChoDau, KichThuoc, TrangThai)
    SELECT 
        'CD' + RIGHT('0000' + CAST(
            ISNULL((SELECT MAX(CAST(SUBSTRING(IDChoDauXe, 3, 4) AS INT)) FROM ChoDauXe), 0) 
            + ROW_NUMBER() OVER(ORDER BY (SELECT 1)) 
        AS VARCHAR), 4) + '_A', 
        IDKhuVucNo, TenChoDau, KichThuoc, TrangThai
    FROM inserted;
END;
GO

-- 6. Bảng DatCho (DCxxxx_Date)
IF OBJECT_ID('trg_AutoID_DatCho') IS NOT NULL DROP TRIGGER trg_AutoID_DatCho;
GO
CREATE TRIGGER trg_AutoID_DatCho ON DatCho INSTEAD OF INSERT AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @DateStr VARCHAR(10) = REPLACE(CONVERT(VARCHAR, GETDATE(), 103), '/', '');
    
    INSERT INTO DatCho (IDDatCho, IDKhachHangNo, IDXeNo, IDChoDauNo, IDNhanVienNo, TgianBatDau, TgianKetThuc, TrangThai)
    SELECT 
        'DC' + RIGHT('0000' + CAST(
            ISNULL((SELECT MAX(CAST(SUBSTRING(IDDatCho, 3, 4) AS INT)) FROM DatCho WHERE IDDatCho LIKE '%_' + @DateStr), 0) 
            + ROW_NUMBER() OVER(ORDER BY (SELECT 1)) 
        AS VARCHAR), 4) + '_' + @DateStr,
        IDKhachHangNo, IDXeNo, IDChoDauNo, IDNhanVienNo, TgianBatDau, TgianKetThuc, TrangThai
    FROM inserted;
END;
GO

-- 7. Bảng HoaDon (HDxxxx_Date)
IF OBJECT_ID('trg_AutoID_HoaDon') IS NOT NULL DROP TRIGGER trg_AutoID_HoaDon;
GO
CREATE TRIGGER trg_AutoID_HoaDon ON HoaDon INSTEAD OF INSERT AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @DateStr VARCHAR(10) = REPLACE(CONVERT(VARCHAR, GETDATE(), 103), '/', '');
    
    INSERT INTO HoaDon (IDHoaDon, ThanhTien, NgayTao, LoaiHoaDon, IDVoucher)
    SELECT 
        'HD' + RIGHT('0000' + CAST(
            ISNULL((SELECT MAX(CAST(SUBSTRING(IDHoaDon, 3, 4) AS INT)) FROM HoaDon WHERE IDHoaDon LIKE '%_' + @DateStr), 0) 
            + ROW_NUMBER() OVER(ORDER BY (SELECT 1)) 
        AS VARCHAR), 4) + '_' + @DateStr,
        ThanhTien, ISNULL(NgayTao, GETDATE()), LoaiHoaDon, IDVoucher
    FROM inserted;
END;
GO

-- 8. Bảng PhieuGiuXe (PXxxxx_Time)
IF OBJECT_ID('trg_AutoID_PhieuGiuXe') IS NOT NULL DROP TRIGGER trg_AutoID_PhieuGiuXe;
GO
CREATE TRIGGER trg_AutoID_PhieuGiuXe ON PhieuGiuXe INSTEAD OF INSERT AS
BEGIN
    SET NOCOUNT ON;
    -- Tạo ID ngẫu nhiên hoặc theo time để tránh trùng lặp
    DECLARE @TimeStamp VARCHAR(12) = RIGHT(REPLACE(REPLACE(REPLACE(CONVERT(VARCHAR, GETDATE(), 120), '-', ''), ':', ''), ' ', ''), 12);
    
    INSERT INTO PhieuGiuXe (IDPhieuGiuXe, IDKhachHangNo, IDXeNo, IDChoDauNo, IDNhanVienVao, IDNhanVienRa, IDHoaDonNo, TgianVao, TgianRa, TrangThai)
    SELECT 
        'PX' + @TimeStamp + CAST(ROW_NUMBER() OVER(ORDER BY (SELECT 1)) AS VARCHAR),
        IDKhachHangNo, IDXeNo, IDChoDauNo, IDNhanVienVao, IDNhanVienRa, IDHoaDonNo, ISNULL(TgianVao, GETDATE()), TgianRa, TrangThai
    FROM inserted;
END;
GO

-- 9. Bảng ChiTietHoaDon (CTHD_ + IDHoaDon)
IF OBJECT_ID('trg_AutoID_ChiTietHoaDon') IS NOT NULL DROP TRIGGER trg_AutoID_ChiTietHoaDon;
GO
CREATE TRIGGER trg_AutoID_ChiTietHoaDon ON ChiTietHoaDon INSTEAD OF INSERT AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO ChiTietHoaDon (IDChiTietHoaDon, IDTheXeThangNo, IDDatChoNo, IDHoaDonNo, TongTien)
    SELECT 
        'CTHD_' + IDHoaDonNo + CAST(ROW_NUMBER() OVER(ORDER BY (SELECT 1)) AS VARCHAR), -- Simple suffix
        IDTheXeThangNo, IDDatChoNo, IDHoaDonNo, TongTien
    FROM inserted;
END;
GO

-- 10. Bảng ThanhToan (TTxxxxx_PhuongThuc)
IF OBJECT_ID('trg_AutoID_ThanhToan') IS NOT NULL DROP TRIGGER trg_AutoID_ThanhToan;
GO
CREATE TRIGGER trg_AutoID_ThanhToan ON ThanhToan INSTEAD OF INSERT AS
BEGIN
    SET NOCOUNT ON;
    DECLARE cur CURSOR FOR SELECT IDHoaDonNo, PhuongThuc, TrangThai, NgayThanhToan FROM inserted;
    DECLARE @HD VARCHAR(20), @PT NVARCHAR(50), @STT BIT, @Ngay DATETIME;
    
    OPEN cur; FETCH NEXT FROM cur INTO @HD, @PT, @STT, @Ngay;
    WHILE @@FETCH_STATUS = 0
    BEGIN
        DECLARE @Suffix VARCHAR(5) = '_TM';
        IF @PT LIKE N'%Chuyển khoản%' SET @Suffix = '_CK';
        ELSE IF @PT LIKE N'%Thẻ%' SET @Suffix = '_TH';
        
        DECLARE @MaxID VARCHAR(15);
        DECLARE @NextNum INT;
        SELECT @MaxID = MAX(IDThanhToan) FROM ThanhToan WHERE IDThanhToan LIKE 'TT%' + @Suffix;
        
        IF @MaxID IS NULL SET @NextNum = 1;
        ELSE SET @NextNum = CAST(SUBSTRING(@MaxID, 3, 5) AS INT) + 1;
            
        DECLARE @NewID VARCHAR(15) = 'TT' + RIGHT('00000' + CAST(@NextNum AS VARCHAR), 5) + @Suffix;
        
        INSERT INTO ThanhToan (IDThanhToan, IDHoaDonNo, PhuongThuc, TrangThai, NgayThanhToan)
        VALUES (@NewID, @HD, @PT, @STT, ISNULL(@Ngay, GETDATE()));
        
        FETCH NEXT FROM cur INTO @HD, @PT, @STT, @Ngay;
    END
    CLOSE cur; DEALLOCATE cur;
END;
GO

-- 11. Bảng TheXeThang (TXTxxx_xxT)
IF OBJECT_ID('trg_AutoID_TheXeThang') IS NOT NULL DROP TRIGGER trg_AutoID_TheXeThang;
GO
CREATE TRIGGER trg_AutoID_TheXeThang ON TheXeThang INSTEAD OF INSERT AS
BEGIN
    SET NOCOUNT ON;
    -- TXT001_12T
    INSERT INTO TheXeThang (IDTheThang, IDKhachHangNo, IDXeNo, TenTheXe, NgayDangKy, NgayHetHan, TrangThai)
    SELECT 
        'TXT' + RIGHT('000' + CAST(
             ISNULL((SELECT MAX(CAST(SUBSTRING(IDTheThang, 4, 3) AS INT)) FROM TheXeThang), 0) 
            + ROW_NUMBER() OVER(ORDER BY (SELECT 1)) 
        AS VARCHAR), 3) + '_1M', -- Default 1M suffix for auto
        IDKhachHangNo, IDXeNo, TenTheXe, ISNULL(NgayDangKy, GETDATE()), NgayHetHan, TrangThai
    FROM inserted;
END;
GO


-- =======================================================
-- BỔ SUNG CÁC BẢNG CÒN LẠI
-- =======================================================

-- 12. Bảng VaiTro (VTxx_XX)
IF OBJECT_ID('trg_AutoID_VaiTro') IS NOT NULL DROP TRIGGER trg_AutoID_VaiTro;
GO
CREATE TRIGGER trg_AutoID_VaiTro ON VaiTro INSTEAD OF INSERT AS
BEGIN
    SET NOCOUNT ON;
    -- Format: VT01_NV. Cố định prefix VT
    INSERT INTO VaiTro (IDVaiTro, TenVaiTro)
    SELECT 
        'VT' + RIGHT('00' + CAST(
            ISNULL((SELECT MAX(CAST(SUBSTRING(IDVaiTro, 3, 2) AS INT)) FROM VaiTro), 0) 
            + ROW_NUMBER() OVER(ORDER BY (SELECT 1)) 
        AS VARCHAR), 2) + '_XX', 
        TenVaiTro
    FROM inserted;
END;
GO

-- 13. Bảng LoaiXe (LXxx_XX)
IF OBJECT_ID('trg_AutoID_LoaiXe') IS NOT NULL DROP TRIGGER trg_AutoID_LoaiXe;
GO
CREATE TRIGGER trg_AutoID_LoaiXe ON LoaiXe INSTEAD OF INSERT AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO LoaiXe (IDLoaiXe, TenLoaiXe)
    SELECT 
        'LX' + RIGHT('00' + CAST(
            ISNULL((SELECT MAX(CAST(SUBSTRING(IDLoaiXe, 3, 2) AS INT)) FROM LoaiXe), 0) 
            + ROW_NUMBER() OVER(ORDER BY (SELECT 1)) 
        AS VARCHAR), 2) + '_XX', 
        TenLoaiXe
    FROM inserted;
END;
GO

-- 14. Bảng CaLam (CLxx_X)
IF OBJECT_ID('trg_AutoID_CaLam') IS NOT NULL DROP TRIGGER trg_AutoID_CaLam;
GO
CREATE TRIGGER trg_AutoID_CaLam ON CaLam INSTEAD OF INSERT AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO CaLam (IDCaLam, TenCa, TgianBatDau, TgianKetThuc, HeSoLuong)
    SELECT 
        'CL' + RIGHT('00' + CAST(
            ISNULL((SELECT MAX(CAST(SUBSTRING(IDCaLam, 3, 2) AS INT)) FROM CaLam), 0) 
            + ROW_NUMBER() OVER(ORDER BY (SELECT 1)) 
        AS VARCHAR), 2) + '_X', 
        TenCa, TgianBatDau, TgianKetThuc, HeSoLuong
    FROM inserted;
END;
GO

-- 15. Bảng ChuBaiXe (CBxxx)
IF OBJECT_ID('trg_AutoID_ChuBaiXe') IS NOT NULL DROP TRIGGER trg_AutoID_ChuBaiXe;
GO
CREATE TRIGGER trg_AutoID_ChuBaiXe ON ChuBaiXe INSTEAD OF INSERT AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO ChuBaiXe (IDChuBaiXe, IDTaiKhoanNo, TenChuBai, SDT, Email, CCCD, DiaChi)
    SELECT 
        'CB' + RIGHT('000' + CAST(
            ISNULL((SELECT MAX(CAST(SUBSTRING(IDChuBaiXe, 3, 3) AS INT)) FROM ChuBaiXe), 0) 
            + ROW_NUMBER() OVER(ORDER BY (SELECT 1)) 
        AS VARCHAR), 3),
        IDTaiKhoanNo, TenChuBai, SDT, Email, CCCD, DiaChi
    FROM inserted;
END;
GO

-- 16. Bảng KhuVuc (KVxxx_X)
IF OBJECT_ID('trg_AutoID_KhuVuc') IS NOT NULL DROP TRIGGER trg_AutoID_KhuVuc;
GO
CREATE TRIGGER trg_AutoID_KhuVuc ON KhuVuc INSTEAD OF INSERT AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO KhuVuc (IDKhuVuc, IDBaiDoNo, TenKhuVuc, SucChua, HinhAnh)
    SELECT 
        'KV' + RIGHT('000' + CAST(
            ISNULL((SELECT MAX(CAST(SUBSTRING(IDKhuVuc, 3, 3) AS INT)) FROM KhuVuc), 0) 
            + ROW_NUMBER() OVER(ORDER BY (SELECT 1)) 
        AS VARCHAR), 3) + '_X', 
        IDBaiDoNo, TenKhuVuc, SucChua, HinhAnh
    FROM inserted;
END;
GO

-- 17. Bảng ThietBi (TBxxx_XX)
IF OBJECT_ID('trg_AutoID_ThietBi') IS NOT NULL DROP TRIGGER trg_AutoID_ThietBi;
GO
CREATE TRIGGER trg_AutoID_ThietBi ON ThietBi INSTEAD OF INSERT AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO ThietBi (IDThietBi, IDKhuVucNo, TenThietBi, LoaiThietBi, TrangThai, NgayCaiDat, GiaLapDat)
    SELECT 
        'TB' + RIGHT('000' + CAST(
            ISNULL((SELECT MAX(CAST(SUBSTRING(IDThietBi, 3, 3) AS INT)) FROM ThietBi), 0) 
            + ROW_NUMBER() OVER(ORDER BY (SELECT 1)) 
        AS VARCHAR), 3) + '_XX', 
        IDKhuVucNo, TenThietBi, LoaiThietBi, TrangThai, NgayCaiDat, GiaLapDat
    FROM inserted;
END;
GO

-- 18. Bảng Voucher (VCxxxxx)
IF OBJECT_ID('trg_AutoID_Voucher') IS NOT NULL DROP TRIGGER trg_AutoID_Voucher;
GO
CREATE TRIGGER trg_AutoID_Voucher ON Voucher INSTEAD OF INSERT AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO Voucher (IDVoucher, IDBaiDoNo, TenVoucher, GiaTri, HanSuDung, SoLuong, TrangThai, MaCode)
    SELECT 
        'VC' + RIGHT('00000' + CAST(
            ISNULL((SELECT MAX(CAST(SUBSTRING(IDVoucher, 3, 5) AS INT)) FROM Voucher), 0) 
            + ROW_NUMBER() OVER(ORDER BY (SELECT 1)) 
        AS VARCHAR), 5), 
        IDBaiDoNo, TenVoucher, GiaTri, HanSuDung, SoLuong, TrangThai, MaCode
    FROM inserted;
END;
GO

-- 19. Bảng BangGia (BGxxx_XX)
IF OBJECT_ID('trg_AutoID_BangGia') IS NOT NULL DROP TRIGGER trg_AutoID_BangGia;
GO
CREATE TRIGGER trg_AutoID_BangGia ON BangGia INSTEAD OF INSERT AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO BangGia (IDBangGia, IDBaiDoNo, IDLoaiXeNo, TenBangGia, HieuLuc)
    SELECT 
        'BG' + RIGHT('000' + CAST(
            ISNULL((SELECT MAX(CAST(SUBSTRING(IDBangGia, 3, 3) AS INT)) FROM BangGia), 0) 
            + ROW_NUMBER() OVER(ORDER BY (SELECT 1)) 
        AS VARCHAR), 3) + '_XX', 
        IDBaiDoNo, IDLoaiXeNo, TenBangGia, HieuLuc
    FROM inserted;
END;
GO

-- 20. Bảng LoaiHinhTinhPhi (LHxxx_XXXX_XX)
IF OBJECT_ID('trg_AutoID_LoaiHinhTinhPhi') IS NOT NULL DROP TRIGGER trg_AutoID_LoaiHinhTinhPhi;
GO
CREATE TRIGGER trg_AutoID_LoaiHinhTinhPhi ON LoaiHinhTinhPhi INSTEAD OF INSERT AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO LoaiHinhTinhPhi (IDLoaiHinhTinhPhi, IDBangGiaNo, TenLoaiHinh, DonViThoiGian, GiaTien)
    SELECT 
        'LH' + RIGHT('000' + CAST(
            ISNULL((SELECT MAX(CAST(SUBSTRING(IDLoaiHinhTinhPhi, 3, 3) AS INT)) FROM LoaiHinhTinhPhi), 0) 
            + ROW_NUMBER() OVER(ORDER BY (SELECT 1)) 
        AS VARCHAR), 3) + '_XXX', 
        IDBangGiaNo, TenLoaiHinh, DonViThoiGian, GiaTien
    FROM inserted;
END;
GO

-- 21. Bảng KhungGio (KGxx_XX)
IF OBJECT_ID('trg_AutoID_KhungGio') IS NOT NULL DROP TRIGGER trg_AutoID_KhungGio;
GO
CREATE TRIGGER trg_AutoID_KhungGio ON KhungGio INSTEAD OF INSERT AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO KhungGio (IDKhungGio, IDLoaiHinhTinhPhiNo, TenKhungGio, ThoiGianBatDau, ThoiGianKetThuc)
    SELECT 
        'KG' + RIGHT('00' + CAST(
            ISNULL((SELECT MAX(CAST(SUBSTRING(IDKhungGio, 3, 2) AS INT)) FROM KhungGio), 0) 
            + ROW_NUMBER() OVER(ORDER BY (SELECT 1)) 
        AS VARCHAR), 2) + '_XX', 
        IDLoaiHinhTinhPhiNo, TenKhungGio, ThoiGianBatDau, ThoiGianKetThuc
    FROM inserted;
END;
GO

-- 22. Bảng LichLamViec (LLVxxxxx_XXX)
IF OBJECT_ID('trg_AutoID_LichLamViec') IS NOT NULL DROP TRIGGER trg_AutoID_LichLamViec;
GO
CREATE TRIGGER trg_AutoID_LichLamViec ON LichLamViec INSTEAD OF INSERT AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO LichLamViec (IDLichLamViec, IDNhanVienNo, IDCaLamNo, IDBaiDoNo, NgayBatDau, NgayKetThuc, TrangThai, SoNgayDaLam)
    SELECT 
        'LLV' + RIGHT('00000' + CAST(
            ISNULL((SELECT MAX(CAST(SUBSTRING(IDLichLamViec, 4, 5) AS INT)) FROM LichLamViec), 0) 
            + ROW_NUMBER() OVER(ORDER BY (SELECT 1)) 
        AS VARCHAR), 5) + '_001', 
        IDNhanVienNo, IDCaLamNo, IDBaiDoNo, NgayBatDau, NgayKetThuc, TrangThai, SoNgayDaLam
    FROM inserted;
END;
GO

-- 23. Bảng SuCo (SCxxx_XX)
IF OBJECT_ID('trg_AutoID_SuCo') IS NOT NULL DROP TRIGGER trg_AutoID_SuCo;
GO
CREATE TRIGGER trg_AutoID_SuCo ON SuCo INSTEAD OF INSERT AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO SuCo (IDSuCo, IDNhanVienNo, IDThietBiNo, MoTa, MucDo, TrangThaiXuLy)
    SELECT 
        'SC' + RIGHT('000' + CAST(
            ISNULL((SELECT MAX(CAST(SUBSTRING(IDSuCo, 3, 3) AS INT)) FROM SuCo), 0) 
            + ROW_NUMBER() OVER(ORDER BY (SELECT 1)) 
        AS VARCHAR), 3) + '_XX', 
        IDNhanVienNo, IDThietBiNo, MoTa, MucDo, TrangThaiXuLy
    FROM inserted;
END;
GO

-- 24. Bảng DanhGia (DGxxx_XXXX)
IF OBJECT_ID('trg_AutoID_DanhGia') IS NOT NULL DROP TRIGGER trg_AutoID_DanhGia;
GO
CREATE TRIGGER trg_AutoID_DanhGia ON DanhGia INSTEAD OF INSERT AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO DanhGia (IDDanhGia, IDKhachHangNo, IDHoaDonNo, NoiDung, DiemDanhGia, NgayDanhGia)
    SELECT 
        'DG' + RIGHT('000' + CAST(
            ISNULL((SELECT MAX(CAST(SUBSTRING(IDDanhGia, 3, 3) AS INT)) FROM DanhGia), 0) 
            + ROW_NUMBER() OVER(ORDER BY (SELECT 1)) 
        AS VARCHAR), 3) + '_XXXX', 
        IDKhachHangNo, IDHoaDonNo, NoiDung, DiemDanhGia, ISNULL(NgayDanhGia, GETDATE())
    FROM inserted;
END;
GO
