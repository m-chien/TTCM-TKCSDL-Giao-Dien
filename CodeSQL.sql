USE master;
GO

IF EXISTS (SELECT * FROM sys.databases WHERE name = 'ParkingLot')
BEGIN
    ALTER DATABASE ParkingLot SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE ParkingLot;
END
GO

CREATE DATABASE ParkingLot;
GO

USE ParkingLot;
GO

-- 1. DANH MỤC & CẤU HÌNH
CREATE TABLE VaiTro (
    ID INT PRIMARY KEY IDENTITY(1,1),
    TenVaiTro NVARCHAR(50) NOT NULL
);

CREATE TABLE LoaiXe (
    ID INT PRIMARY KEY IDENTITY(1,1),
    TenLoaiXe NVARCHAR(50) NOT NULL
);

CREATE TABLE CaLam (
    ID INT PRIMARY KEY IDENTITY(1,1),
    TenCa NVARCHAR(50),
    TgianBatDau TIME,
    TgianKetThuc TIME,
    HeSoLuong FLOAT
);

-- 2. HỆ THỐNG TÀI KHOẢN
CREATE TABLE TaiKhoan (
    ID INT PRIMARY KEY IDENTITY(1,1),
    IDVaiTro INT CONSTRAINT FK_TaiKhoan_VaiTro FOREIGN KEY REFERENCES VaiTro(ID) 
            ON UPDATE CASCADE 
            ON DELETE CASCADE,
    TenDangNhap VARCHAR(50) UNIQUE NOT NULL,
    MatKhau VARCHAR(255) NOT NULL,
    AnhDaiDien VARCHAR(255),
    TrangThai BIT DEFAULT 1
);

CREATE TABLE NhanVien (
    ID INT PRIMARY KEY IDENTITY(1,1),
    IDTaiKhoan INT CONSTRAINT FK_NhanVien_TaiKhoan FOREIGN KEY REFERENCES TaiKhoan(ID) 
            ON UPDATE CASCADE 
            ON DELETE CASCADE,
    TenNhanVien NVARCHAR(100),
    SDT VARCHAR(11) CONSTRAINT CK_NhanVien_SDT CHECK (SDT NOT LIKE '%[^0-9]%' AND LEN(SDT) >= 10),
    Email VARCHAR(100) CONSTRAINT CK_NhanVien_Email CHECK (Email LIKE '%_@__%.__%'),
    ChucVu NVARCHAR(50),
    LuongCB DECIMAL(18,2)
);

CREATE TABLE KhachHang (
    ID INT PRIMARY KEY IDENTITY(1,1),
    IDTaiKhoan INT CONSTRAINT FK_KhachHang_TaiKhoan FOREIGN KEY REFERENCES TaiKhoan(ID) 
                ON UPDATE CASCADE 
                ON DELETE CASCADE,
    HoTen NVARCHAR(100),
    SDT VARCHAR(11) CONSTRAINT CK_KhachHang_SDT CHECK (SDT NOT LIKE '%[^0-9]%' AND LEN(SDT) >= 10),
    CCCD VARCHAR(20),
    BangLaiXe VARCHAR(20),
    DiaChi NVARCHAR(255),
    LoaiKH NVARCHAR(50) CONSTRAINT CK_KhachHang_LoaiKH CHECK (LoaiKH IN (N'Vãng lai', N'Thường xuyên', N'VIP')),
    SoTK VARCHAR(20),
    TenNganHang NVARCHAR(50)
);

CREATE TABLE ChuBaiXe (
    ID INT PRIMARY KEY IDENTITY(1,1),
    IDTaiKhoan INT CONSTRAINT FK_ChuBaiXe_TaiKhoan FOREIGN KEY REFERENCES TaiKhoan(ID) 
            ON UPDATE CASCADE 
            ON DELETE CASCADE,
    TenChuBai NVARCHAR(100),
    SDT VARCHAR(11) CONSTRAINT CK_ChuBaiXe_SDT CHECK (SDT NOT LIKE '%[^0-9]%' AND LEN(SDT) >= 10),
    Email VARCHAR(100) CONSTRAINT CK_ChuBaiXe_Email CHECK (Email LIKE '%_@__%.__%'),
    CCCD VARCHAR(20),
    DiaChi NVARCHAR(255)
);

-- 3. XE & TÀI SẢN
CREATE TABLE Xe (
    BienSoXe VARCHAR(20) PRIMARY KEY,
    IDLoaiXe INT CONSTRAINT FK_Xe_LoaiXe FOREIGN KEY REFERENCES LoaiXe(ID)  
            ON UPDATE CASCADE 
            ON DELETE CASCADE,
    TenXe NVARCHAR(100),
    Hang NVARCHAR(50),
    MauSac NVARCHAR(50),
    HinhAnh NVARCHAR(255)
);

CREATE TABLE KhachHang_Xe (
    ID INT PRIMARY KEY IDENTITY(1,1),
    IDKhachHang INT CONSTRAINT FK_KHXe_KhachHang FOREIGN KEY REFERENCES KhachHang(ID) 
            ON UPDATE NO ACTION 
            ON DELETE NO ACTION, 
    IDXe VARCHAR(20) CONSTRAINT FK_KHXe_Xe FOREIGN KEY REFERENCES Xe(BienSoXe) 
            ON UPDATE CASCADE 
            ON DELETE CASCADE,
    LoaiSoHuu NVARCHAR(50)
);

-- 4. CẤU TRÚC BÃI ĐỖ
CREATE TABLE BaiDo (
    ID INT PRIMARY KEY IDENTITY(1,1),
    IDChuBai INT CONSTRAINT FK_BaiDo_ChuBai FOREIGN KEY REFERENCES ChuBaiXe(ID) 
            ON UPDATE CASCADE 
            ON DELETE CASCADE,
    TenBai NVARCHAR(100),
    ViTri NVARCHAR(255),
    SucChua INT,
    TrangThai NVARCHAR(50) CONSTRAINT CK_BaiDo_TrangThai CHECK (TrangThai IN (N'Hoạt động', N'Đóng cửa', N'Bảo trì', N'Tạm dừng')),
    HinhAnh NVARCHAR(255)
);

CREATE TABLE KhuVuc (
    ID INT PRIMARY KEY IDENTITY(1,1),
    IDBaiDo INT CONSTRAINT FK_KhuVuc_BaiDo FOREIGN KEY REFERENCES BaiDo(ID) 
            ON UPDATE CASCADE 
            ON DELETE CASCADE,
    TenKhuVuc NVARCHAR(50),
    SucChua INT,
    HinhAnh VARCHAR(255)
);

CREATE TABLE ChoDauXe (
    ID INT PRIMARY KEY IDENTITY(1,1),
    IDKhuVuc INT CONSTRAINT FK_ChoDau_KhuVuc FOREIGN KEY REFERENCES KhuVuc(ID) 
            ON UPDATE CASCADE 
            ON DELETE CASCADE,
    TenChoDau NVARCHAR(20),
    KichThuoc VARCHAR(50),
    TrangThai NVARCHAR(50) CONSTRAINT CK_ChoDauXe_TrangThai CHECK (TrangThai IN (N'Trống', N'Đã đặt', N'Đang đỗ', N'Bảo trì'))
);

CREATE TABLE ThietBi (
    ID INT PRIMARY KEY IDENTITY(1,1),
    IDKhuVuc INT CONSTRAINT FK_ThietBi_KhuVuc FOREIGN KEY REFERENCES KhuVuc(ID) 
            ON UPDATE CASCADE 
            ON DELETE CASCADE,
    TenThietBi NVARCHAR(100),
    LoaiThietBi NVARCHAR(50),
    TrangThai NVARCHAR(50) CONSTRAINT CK_ThietBi_TrangThai CHECK (TrangThai IN (N'Hoạt động', N'Hỏng', N'Bảo trì', N'Thanh lý')),
    NgayCaiDat DATE,
    GiaLapDat DECIMAL(18,2)
);

-- 5. GIÁ & VOUCHER
CREATE TABLE BangGia (
    ID INT PRIMARY KEY IDENTITY(1,1),
    IDBaiDo INT CONSTRAINT FK_BangGia_BaiDo FOREIGN KEY REFERENCES BaiDo(ID) 
            ON UPDATE CASCADE 
            ON DELETE CASCADE,
    IDLoaiXe INT CONSTRAINT FK_BangGia_LoaiXe FOREIGN KEY REFERENCES LoaiXe(ID) 
            ON UPDATE CASCADE 
            ON DELETE NO ACTION,
    TenBangGia NVARCHAR(100),
    HieuLuc BIT DEFAULT 1
);

CREATE TABLE LoaiHinhTinhPhi (
    ID INT PRIMARY KEY IDENTITY(1,1),
    IDBangGia INT CONSTRAINT FK_LHTP_BangGia FOREIGN KEY REFERENCES BangGia(ID) 
            ON UPDATE CASCADE 
            ON DELETE CASCADE,
    TenLoaiHinh NVARCHAR(100),
    DonViThoiGian NVARCHAR(50) CONSTRAINT CK_LoaiHinhTinhPhi_DonViThoiGian CHECK(DonViThoiGian IN (N'Giờ',N'Ngày',N'Tháng',N'Năm')),
    GiaTien DECIMAL(18,2) NOT NULL
);

CREATE TABLE KhungGio (
    ID INT PRIMARY KEY IDENTITY(1,1),
    IDLoaiHinhTinhPhi INT CONSTRAINT FK_KhungGio_LHTP FOREIGN KEY REFERENCES LoaiHinhTinhPhi(ID) 
            ON UPDATE CASCADE 
            ON DELETE CASCADE,
    TenKhungGio NVARCHAR(50),
    ThoiGianBatDau TIME,
    ThoiGianKetThuc TIME
);

CREATE TABLE TheXeThang (
    ID INT PRIMARY KEY IDENTITY(1,1),
    IDKhachHang_Xe INT CONSTRAINT FK_TheXe_KHXe FOREIGN KEY REFERENCES KhachHang_Xe(ID) 
            ON UPDATE CASCADE 
            ON DELETE CASCADE,
    TenTheXe NVARCHAR(100),
    NgayDangKy DATE,
    NgayHetHan DATE,
    TrangThai BIT DEFAULT 1
);

CREATE TABLE Voucher (
    ID INT PRIMARY KEY IDENTITY(1,1),
    IDBaiDo INT CONSTRAINT FK_Voucher_BaiDo FOREIGN KEY REFERENCES BaiDo(ID)
            ON UPDATE CASCADE 
            ON DELETE CASCADE,
    TenVoucher NVARCHAR(100),
    GiaTri DECIMAL(18,2),
    HanSuDung DATE,
    SoLuong INT,
    TrangThai BIT DEFAULT 1,
    MaCode VARCHAR(20) UNIQUE
);

-- 6. NGHIỆP VỤ (CORE)
CREATE TABLE DatCho (
    ID INT PRIMARY KEY IDENTITY(1,1),
    IDKhachHang INT CONSTRAINT FK_DatCho_KhachHang FOREIGN KEY REFERENCES KhachHang(ID) 
            ON UPDATE NO ACTION 
            ON DELETE NO ACTION, 
    IDNhanVien INT CONSTRAINT FK_DatCho_NhanVien FOREIGN KEY REFERENCES NhanVien(ID) 
            ON UPDATE NO ACTION 
            ON DELETE NO ACTION, 
    IDChoDau INT CONSTRAINT FK_DatCho_ChoDau FOREIGN KEY REFERENCES ChoDauXe(ID) 
            ON UPDATE NO ACTION 
            ON DELETE NO ACTION, 
    TgianBatDau DATETIME,
    TgianKetThuc DATETIME,
    TrangThai NVARCHAR(50) CONSTRAINT CK_DatCho_TrangThai CHECK (TrangThai IN (N'Đã đặt', N'Đã hủy', N'Hoàn thành', N'Quá hạn'))
);

CREATE TABLE HoaDon (
    ID INT PRIMARY KEY IDENTITY(1,1),
    ThanhTien DECIMAL(18,2),
    NgayTao DATETIME DEFAULT GETDATE(),
    LoaiHoaDon NVARCHAR(50),
    IDVoucher INT CONSTRAINT FK_HoaDon_Voucher FOREIGN KEY REFERENCES Voucher(ID) 
            ON UPDATE NO ACTION 
            ON DELETE SET NULL 
);

CREATE TABLE PhieuGiuXe (
    ID INT PRIMARY KEY IDENTITY(1,1),
    IDXe VARCHAR(20) CONSTRAINT FK_PGX_Xe FOREIGN KEY REFERENCES Xe(BienSoXe) 
            ON UPDATE NO ACTION 
            ON DELETE NO ACTION, 
    IDChoDau INT CONSTRAINT FK_PGX_ChoDau FOREIGN KEY REFERENCES ChoDauXe(ID) 
            ON UPDATE NO ACTION 
            ON DELETE NO ACTION, 
    IDNhanVien INT CONSTRAINT FK_PGX_NhanVien FOREIGN KEY REFERENCES NhanVien(ID) 
            ON UPDATE NO ACTION 
            ON DELETE NO ACTION, 
    IDHoaDon INT CONSTRAINT FK_PGX_HoaDon FOREIGN KEY REFERENCES HoaDon(ID) 
            ON UPDATE NO ACTION 
            ON DELETE NO ACTION,
    TgianVao DATETIME,
    TgianRa DATETIME,
    TrangThai NVARCHAR(50) CONSTRAINT CK_PhieuGiuXe_TrangThai CHECK (TrangThai IN (N'Đang gửi', N'Đã lấy', N'Quá hạn', N'Mất vé'))
);

CREATE TABLE ChiTietHoaDon (
    ID INT PRIMARY KEY IDENTITY(1,1),
    IDTheXeThang INT CONSTRAINT FK_CTHD_TheXe FOREIGN KEY REFERENCES TheXeThang(ID) 
            ON UPDATE NO ACTION 
            ON DELETE NO ACTION,
    IDDatCho INT CONSTRAINT FK_CTHD_DatCho FOREIGN KEY REFERENCES DatCho(ID) 
            ON UPDATE NO ACTION 
            ON DELETE NO ACTION,
    IDHoaDon INT CONSTRAINT FK_CTHD_HoaDon FOREIGN KEY REFERENCES HoaDon(ID) 
            ON UPDATE CASCADE 
            ON DELETE CASCADE,
    TongTien DECIMAL(18,2)
);

CREATE TABLE ThanhToan (
    ID INT PRIMARY KEY IDENTITY(1,1),
    IDHoaDon INT CONSTRAINT FK_ThanhToan_HoaDon FOREIGN KEY REFERENCES HoaDon(ID) 
            ON UPDATE NO ACTION 
            ON DELETE NO ACTION,
    PhuongThuc NVARCHAR(50) CONSTRAINT CK_ThanhToan_PhuongThuc CHECK (PhuongThuc IN (N'Tiền mặt', N'Thẻ', N'QR Code', N'Chuyển khoản')),
    TrangThai BIT,
    NgayThanhToan DATETIME DEFAULT GETDATE()
);

-- 7. BẢNG PHỤ TRỢ 
CREATE TABLE LichLamViec (
    ID INT PRIMARY KEY IDENTITY(1,1),
    IDNhanVien INT CONSTRAINT FK_Lich_NhanVien FOREIGN KEY REFERENCES NhanVien(ID) 
            ON UPDATE CASCADE 
            ON DELETE CASCADE,
    IDCaLam INT CONSTRAINT FK_Lich_CaLam FOREIGN KEY REFERENCES CaLam(ID) 
            ON UPDATE CASCADE 
            ON DELETE CASCADE,
    IDBaiDo INT CONSTRAINT FK_Lich_BaiDo FOREIGN KEY REFERENCES BaiDo(ID) 
            ON UPDATE NO ACTION 
            ON DELETE NO ACTION,
    NgayBatDau DATE,
    NgayKetThuc DATE,
    TrangThai BIT DEFAULT 0,
    SoNgayDaLam INT
);

CREATE TABLE SuCo (
    ID INT PRIMARY KEY IDENTITY(1,1),
    IDNhanVien INT CONSTRAINT FK_SuCo_NhanVien FOREIGN KEY REFERENCES NhanVien(ID) 
            ON UPDATE NO ACTION 
            ON DELETE SET NULL, 
    IDThietBi INT CONSTRAINT FK_SuCo_ThietBi FOREIGN KEY REFERENCES ThietBi(ID) 
            ON UPDATE NO ACTION 
            ON DELETE NO ACTION,
    MoTa NVARCHAR(MAX),
    MucDo NVARCHAR(50) CONSTRAINT CK_SuCo_MucDo CHECK (MucDo IN (N'Nhẹ', N'Trung bình', N'Nghiêm trọng')),
    TrangThaiXuLy NVARCHAR(50) CONSTRAINT CK_SuCo_TrangThaiXuLy CHECK (TrangThaiXuLy IN (N'Chưa xử lý', N'Đang xử lý', N'Đã xử lý'))
);

CREATE TABLE DanhGia (
    ID INT PRIMARY KEY IDENTITY(1,1),
    IDKhachHang INT CONSTRAINT FK_DanhGia_KhachHang FOREIGN KEY REFERENCES KhachHang(ID) 
            ON UPDATE CASCADE 
            ON DELETE CASCADE,
    IDHoaDon INT CONSTRAINT FK_DanhGia_HoaDon FOREIGN KEY REFERENCES HoaDon(ID) 
            ON UPDATE NO ACTION 
            ON DELETE NO ACTION, 
    NoiDung NVARCHAR(MAX),
    DiemDanhGia INT,
    NgayDanhGia DATETIME DEFAULT GETDATE()
);
GO

-- =====================Insert dữ liệu========================
USE ParkingLot;
GO

INSERT INTO VaiTro (TenVaiTro) VALUES (N'Admin'), (N'Nhân viên'), (N'Khách hàng'), (N'Chủ bãi xe');
INSERT INTO LoaiXe (TenLoaiXe) VALUES (N'Xe Máy'), (N'Ô tô 4 chỗ'), (N'Ô tô 7 chỗ'), (N'Xe Tải nhỏ');
INSERT INTO CaLam (TenCa, TgianBatDau, TgianKetThuc, HeSoLuong) VALUES (N'Ca Sáng', '06:00', '14:00', 1.0), (N'Ca Chiều', '14:00', '22:00', 1.0);

INSERT INTO TaiKhoan (IDVaiTro, TenDangNhap, MatKhau) VALUES 
(1, 'admin', '123456'), 
(2, 'nv_bao', '123456'), 
(3, 'kh_tung', '123456'), 
(3, 'kh_hoa', '123456'), 
(4, 'chu_hung', '123456');

INSERT INTO NhanVien (IDTaiKhoan, TenNhanVien, SDT, Email, LuongCB) 
VALUES (2, N'Nguyễn Văn Bảo', '0901234567', 'bao@parking.com', 7000000);

INSERT INTO KhachHang (IDTaiKhoan, HoTen, SDT, CCCD, BangLaiXe, DiaChi, LoaiKH) VALUES 
(3, N'Phạm Thanh Tùng', '0912345678', '001090000001', 'B1-123456', N'Hà Nội', N'Thường xuyên'),
(4, N'Lê Thị Hoa', '0987654321', '001090000002', 'B2-987654', N'Đà Nẵng', N'Vãng lai');

INSERT INTO ChuBaiXe (IDTaiKhoan, TenChuBai, SDT, Email, CCCD, DiaChi) 
VALUES (5, N'Trần Văn Hùng', '0999888777', 'hung@owner.com', '001090999999', N'TP HCM');

INSERT INTO Xe (BienSoXe, IDLoaiXe, TenXe, Hang, MauSac) VALUES 
('30A-123.45', 2, 'Vios', 'Toyota', N'Trắng'),
('29H-999.99', 1, 'SH 150i', 'Honda', N'Đen'),
('43A-567.89', 3, 'CX-5', 'Mazda', N'Đỏ');

INSERT INTO KhachHang_Xe (IDKhachHang, IDXe, LoaiSoHuu) VALUES 
(1, '30A-123.45', N'Chính chủ'), 
(2, '43A-567.89', N'Thuê'),
(1, '29H-999.99', N'Chính chủ');

INSERT INTO BaiDo (IDChuBai, TenBai, ViTri, SucChua, TrangThai) 
VALUES (1, N'Bãi xe Royal City', N'72A Nguyễn Trãi', 500, N'Hoạt động');

INSERT INTO KhuVuc (IDBaiDo, TenKhuVuc, SucChua) VALUES 
(1, N'Khu A - Ô tô', 200),
(1, N'Khu B - Xe máy', 300);

INSERT INTO ChoDauXe (IDKhuVuc, TenChoDau, KichThuoc, TrangThai) VALUES 
(1, 'A-01', N'5.0x2.5m', N'Trống'),
(1, 'A-02', N'5.0x2.5m', N'Trống'),
(1, 'A-03', N'5.0x2.5m', N'Trống'),
(2, 'B-01', N'2.0x1.0m', N'Trống'),
(2, 'B-02', N'2.0x1.0m', N'Trống');

INSERT INTO ThietBi (IDKhuVuc, TenThietBi, LoaiThietBi, TrangThai, NgayCaiDat, GiaLapDat) VALUES 
(1, N'Cam Cổng A1', N'Camera', N'Hoạt động', '2023-01-01', 5000000),
(1, N'Barrier A1', N'Barrier', N'Hoạt động', '2023-01-01', 15000000);

INSERT INTO BangGia (IDBaiDo, IDLoaiXe, TenBangGia) VALUES 
(1, 2, N'Bảng giá Ô tô 2024'),
(1, 1, N'Bảng giá Xe máy 2024');

INSERT INTO LoaiHinhTinhPhi (IDBangGia, TenLoaiHinh, DonViThoiGian, GiaTien) VALUES 
(1, N'Vé lượt ngày', N'Ngày', 30000),
(1, N'Vé tháng', N'Tháng', 1500000),
(2, N'Vé lượt', N'Giờ', 5000);

INSERT INTO KhungGio (IDLoaiHinhTinhPhi, TenKhungGio, ThoiGianBatDau, ThoiGianKetThuc) 
VALUES (1, N'Khung giờ hành chính', '08:00', '17:00');

INSERT INTO Voucher (IDBaiDo, TenVoucher, GiaTri, HanSuDung, SoLuong, TrangThai, MaCode) VALUES 
(1, N'Giảm giá Tết', 10000, '2025-12-31', 50, 1, 'TET2025');

INSERT INTO LichLamViec (IDNhanVien, IDCaLam, IDBaiDo, NgayBatDau, NgayKetThuc, TrangThai, SoNgayDaLam) 
VALUES (1, 1, 1, '2025-01-01', '2025-01-31', 1, 10);

INSERT INTO SuCo (IDNhanVien, IDThietBi, MoTa, MucDo, TrangThaiXuLy) 
VALUES (1, 1, N'Camera bị nhiễu hình ảnh', N'Nhẹ', N'Đang xử lý');

INSERT INTO TheXeThang (IDKhachHang_Xe, TenTheXe, NgayDangKy, NgayHetHan, TrangThai) 
VALUES (1, N'Thẻ tháng T1/2025', '2025-01-01', '2025-01-31', 1);

INSERT INTO DatCho (IDKhachHang, IDNhanVien, IDChoDau, TgianBatDau, TgianKetThuc, TrangThai) 
VALUES (2, NULL, 2, DATEADD(HOUR, 1, GETDATE()), DATEADD(HOUR, 5, GETDATE()), N'Đã đặt');

INSERT INTO PhieuGiuXe (IDXe, IDChoDau, IDNhanVien, IDHoaDon, TgianVao, TgianRa, TrangThai) 
VALUES ('30A-123.45', 1, 1, NULL, GETDATE(), NULL, N'Đang gửi');

INSERT INTO HoaDon (ThanhTien, LoaiHoaDon, IDVoucher) 
VALUES (5000, N'Vé lượt', NULL);

INSERT INTO ThanhToan (IDHoaDon, PhuongThuc, TrangThai) 
VALUES (1, N'Tiền mặt', 1);

INSERT INTO PhieuGiuXe (IDXe, IDChoDau, IDNhanVien, IDHoaDon, TgianVao, TgianRa, TrangThai) 
VALUES ('29H-999.99', 4, 1, 1, DATEADD(HOUR, -2, GETDATE()), GETDATE(), N'Đã lấy');

INSERT INTO ChiTietHoaDon (IDHoaDon, TongTien) 
VALUES (1, 5000);

INSERT INTO DanhGia (IDKhachHang, IDHoaDon, NoiDung, DiemDanhGia) 
VALUES (1, 1, N'Bãi xe sạch sẽ, nhân viên nhiệt tình', 5);
GO

-- 8. FUNCTION & PROCEDURE
-- 1. FUNCTION: Tìm chỗ trống
IF OBJECT_ID('f_TimKiemChoTrong') IS NOT NULL DROP FUNCTION f_TimKiemChoTrong;
GO
CREATE FUNCTION f_TimKiemChoTrong (@IDBaiDo INT)
RETURNS TABLE
AS
RETURN
(
    SELECT bd.TenBai, kv.TenKhuVuc, cd.TenChoDau, cd.KichThuoc, cd.TrangThai
    FROM ChoDauXe cd
    JOIN KhuVuc kv ON cd.IDKhuVuc = kv.ID
    JOIN BaiDo bd ON kv.IDBaiDo = bd.ID
    WHERE cd.TrangThai = N'Trống' 
    AND (@IDBaiDo IS NULL OR bd.ID = @IDBaiDo)
);
GO

-- 2. FUNCTION: Tính doanh thu
IF OBJECT_ID('f_TongDoanhThuThang') IS NOT NULL DROP FUNCTION f_TongDoanhThuThang;
GO
CREATE FUNCTION f_TongDoanhThuThang (@Thang INT, @Nam INT)
RETURNS DECIMAL(18,2)
AS
BEGIN
    DECLARE @TongTien DECIMAL(18,2);
    SELECT @TongTien = SUM(hd.ThanhTien)
    FROM HoaDon hd
    JOIN ThanhToan tt ON hd.ID = tt.IDHoaDon
    WHERE MONTH(tt.NgayThanhToan) = @Thang 
      AND YEAR(tt.NgayThanhToan) = @Nam 
      AND tt.TrangThai = 1; 
    RETURN ISNULL(@TongTien, 0);
END;
GO

-- 3. PROCEDURE: Tìm thông tin xe
IF OBJECT_ID('sp_TimKiemThongTinXe') IS NOT NULL DROP PROCEDURE sp_TimKiemThongTinXe;
GO
CREATE PROCEDURE sp_TimKiemThongTinXe 
    @TuKhoa NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT x.BienSoXe, x.TenXe, kh.HoTen AS ChuSoHuu, cd.TenChoDau, kv.TenKhuVuc,
        CASE 
            WHEN pgx.TgianRa IS NULL THEN N'Đang trong bãi' 
            ELSE N'Đã rời bãi' 
        END AS TrangThaiHienTai,
        pgx.TgianVao, pgx.TgianRa
    FROM Xe x
    LEFT JOIN KhachHang_Xe khx ON x.BienSoXe = khx.IDXe
    LEFT JOIN KhachHang kh ON khx.IDKhachHang = kh.ID
    LEFT JOIN PhieuGiuXe pgx ON x.BienSoXe = pgx.IDXe
    LEFT JOIN ChoDauXe cd ON pgx.IDChoDau = cd.ID
    LEFT JOIN KhuVuc kv ON cd.IDKhuVuc = kv.ID
    WHERE x.BienSoXe LIKE '%' + @TuKhoa + '%' 
       OR kh.HoTen LIKE N'%' + @TuKhoa + '%'
    ORDER BY pgx.TgianVao DESC;
END;
GO

-- 4. PROCEDURE: Báo cáo
IF OBJECT_ID('sp_BaoCaoThongKeTongHop') IS NOT NULL DROP PROCEDURE sp_BaoCaoThongKeTongHop;
GO
CREATE PROCEDURE sp_BaoCaoThongKeTongHop 
    @NgayBatDau DATE, 
    @NgayKetThuc DATE
AS
BEGIN
    SET NOCOUNT ON;
    SELECT CAST(tt.NgayThanhToan AS DATE) AS Ngay,
        COUNT(DISTINCT pgx.ID) AS SoLuotXeVao,
        SUM(hd.ThanhTien) AS DoanhThu,
        COUNT(hd.IDVoucher) AS SoVoucherSuDung
    FROM ThanhToan tt
    JOIN HoaDon hd ON tt.IDHoaDon = hd.ID
    LEFT JOIN PhieuGiuXe pgx ON hd.ID = pgx.IDHoaDon
    WHERE CAST(tt.NgayThanhToan AS DATE) BETWEEN @NgayBatDau AND @NgayKetThuc 
      AND tt.TrangThai = 1
    GROUP BY CAST(tt.NgayThanhToan AS DATE)
    ORDER BY Ngay DESC;
END;
GO

-- 5. TRIGGER: Cập nhật chỗ khi Đặt vé
IF OBJECT_ID('trg_DatCho_CapNhatTrangThai') IS NOT NULL DROP TRIGGER trg_DatCho_CapNhatTrangThai;
GO
CREATE TRIGGER trg_DatCho_CapNhatTrangThai
ON DatCho AFTER INSERT AS
BEGIN
    UPDATE ChoDauXe SET TrangThai = N'Đã đặt'
    FROM ChoDauXe c JOIN inserted i ON c.ID = i.IDChoDau;
END;
GO

-- 6. TRIGGER: Giải phóng chỗ khi Hủy đặt
IF OBJECT_ID('trg_DatCho_GiaiPhongCho') IS NOT NULL DROP TRIGGER trg_DatCho_GiaiPhongCho;
GO
CREATE TRIGGER trg_DatCho_GiaiPhongCho
ON DatCho AFTER UPDATE AS
BEGIN
    UPDATE ChoDauXe SET TrangThai = N'Trống'
    FROM ChoDauXe c JOIN inserted i ON c.ID = i.IDChoDau
    WHERE i.TrangThai IN (N'Đã hủy', N'Hoàn thành', N'Quá hạn') AND c.TrangThai = N'Đã đặt';
END;
GO

-- 7. TRIGGER: Tính tổng tiền hóa đơn
IF OBJECT_ID('trg_ChiTietHD_TinhTongTien') IS NOT NULL DROP TRIGGER trg_ChiTietHD_TinhTongTien;
GO
CREATE TRIGGER trg_ChiTietHD_TinhTongTien
ON ChiTietHoaDon AFTER INSERT, UPDATE, DELETE AS
BEGIN
    DECLARE @AffectedIDs TABLE (IDHoaDon INT);
    INSERT INTO @AffectedIDs SELECT IDHoaDon FROM Inserted UNION SELECT IDHoaDon FROM Deleted;

    UPDATE HoaDon SET ThanhTien = (SELECT ISNULL(SUM(TongTien), 0) FROM ChiTietHoaDon WHERE IDHoaDon = HoaDon.ID)
    WHERE ID IN (SELECT IDHoaDon FROM @AffectedIDs);
END;
GO

-- 8. TRIGGER: Check trùng lịch đặt
IF OBJECT_ID('trg_DatCho_CheckTrungLich') IS NOT NULL DROP TRIGGER trg_DatCho_CheckTrungLich;
GO
CREATE TRIGGER trg_DatCho_CheckTrungLich
ON DatCho AFTER INSERT, UPDATE AS
BEGIN
    IF EXISTS (
        SELECT 1 FROM DatCho d JOIN Inserted i ON d.IDChoDau = i.IDChoDau
        WHERE d.ID <> i.ID AND d.TrangThai NOT IN (N'Đã hủy')
          AND (d.TgianBatDau < i.TgianKetThuc AND d.TgianKetThuc > i.TgianBatDau)
    )
    BEGIN
        ROLLBACK TRANSACTION; RAISERROR (N'Lỗi: Chỗ đã có người đặt khung giờ này!', 16, 1);
    END
END;
GO

-- 9. TRIGGER: Xử lý Voucher
IF OBJECT_ID('trg_HoaDon_XuLyVoucher') IS NOT NULL DROP TRIGGER trg_HoaDon_XuLyVoucher;
GO
CREATE TRIGGER trg_HoaDon_XuLyVoucher
ON HoaDon AFTER INSERT AS
BEGIN
    IF EXISTS (SELECT 1 FROM inserted WHERE IDVoucher IS NOT NULL)
    BEGIN
        IF EXISTS (SELECT 1 FROM Voucher v JOIN inserted i ON v.ID = i.IDVoucher WHERE v.SoLuong <= 0 OR v.HanSuDung < GETDATE())
        BEGIN
            ROLLBACK TRANSACTION; RAISERROR (N'Lỗi: Voucher hết hạn/số lượng!', 16, 1); RETURN;
        END
        UPDATE Voucher SET SoLuong = SoLuong - 1 FROM Voucher v JOIN inserted i ON v.ID = i.IDVoucher;
    END
END;
GO

-- 10. TRIGGER: Validate Thẻ tháng
IF OBJECT_ID('trg_TheXeThang_Validate') IS NOT NULL DROP TRIGGER trg_TheXeThang_Validate;
GO
CREATE TRIGGER trg_TheXeThang_Validate
ON TheXeThang AFTER INSERT, UPDATE AS
BEGIN
    IF EXISTS (SELECT 1 FROM inserted WHERE NgayHetHan <= NgayDangKy)
    BEGIN
        RAISERROR(N'Lỗi: Ngày hết hạn phải sau ngày đăng ký.', 16, 1); ROLLBACK TRANSACTION; RETURN;
    END
    IF UPDATE(NgayHetHan)
    BEGIN
        UPDATE TheXeThang SET TrangThai = 1 FROM TheXeThang t JOIN inserted i ON t.ID = i.ID WHERE i.NgayHetHan > GETDATE() AND i.TrangThai = 0;
    END
END;
GO

-- 11. TRIGGER (QUAN TRỌNG NHẤT): Cập nhật trạng thái chỗ khi Xe Vào/Ra
IF OBJECT_ID('trg_PhieuGiuXe_CapNhatTrangThai') IS NOT NULL DROP TRIGGER trg_PhieuGiuXe_CapNhatTrangThai;
GO
CREATE TRIGGER trg_PhieuGiuXe_CapNhatTrangThai
ON PhieuGiuXe AFTER INSERT, UPDATE AS
BEGIN
    -- Xe vào: Chuyển sang Đang đỗ
    IF EXISTS (SELECT * FROM inserted) AND NOT EXISTS (SELECT * FROM deleted)
    BEGIN
        UPDATE ChoDauXe SET TrangThai = N'Đang đỗ' FROM ChoDauXe c JOIN inserted i ON c.ID = i.IDChoDau;
    END
    -- Xe ra: Chuyển sang Trống
    IF UPDATE(TgianRa)
    BEGIN
        UPDATE ChoDauXe SET TrangThai = N'Trống' FROM ChoDauXe c JOIN inserted i ON c.ID = i.IDChoDau WHERE i.TgianRa IS NOT NULL;
    END
    -- Đổi chỗ
    IF UPDATE(IDChoDau)
    BEGIN
        UPDATE ChoDauXe SET TrangThai = N'Trống' FROM ChoDauXe c JOIN deleted d ON c.ID = d.IDChoDau;
        UPDATE ChoDauXe SET TrangThai = N'Đang đỗ' FROM ChoDauXe c JOIN inserted i ON c.ID = i.IDChoDau;
    END
END;
GO


SELECT * FROM f_TimKiemChoTrong(1);
SELECT dbo.f_TongDoanhThuThang(12, 2025) AS DoanhThu;

EXEC sp_TimKiemThongTinXe @TuKhoa = '30A';

EXEC sp_BaoCaoThongKeTongHop @NgayBatDau = '2024-01-01', @NgayKetThuc = '2026-01-01';

go
-- 8.3. TRIGGER (TỰ ĐỘNG HÓA)
-- T1: Cập nhật trạng thái chỗ khi Đặt vé (DatCho -> Insert)
IF OBJECT_ID('trg_DatCho_CapNhatTrangThai') IS NOT NULL DROP TRIGGER trg_DatCho_CapNhatTrangThai;
GO
CREATE TRIGGER trg_DatCho_CapNhatTrangThai
ON DatCho
AFTER INSERT
AS
BEGIN
    UPDATE ChoDauXe
    SET TrangThai = N'Đã đặt'
    FROM ChoDauXe c
    JOIN inserted i ON c.ID = i.IDChoDau;
END;
GO

-- T2: Giải phóng chỗ khi Hủy/Hoàn thành Đặt vé (DatCho -> Update)
IF OBJECT_ID('trg_DatCho_GiaiPhongCho') IS NOT NULL DROP TRIGGER trg_DatCho_GiaiPhongCho;
GO
CREATE TRIGGER trg_DatCho_GiaiPhongCho
ON DatCho
AFTER UPDATE
AS
BEGIN
    UPDATE ChoDauXe
    SET TrangThai = N'Trống'
    FROM ChoDauXe c 
    JOIN inserted i ON c.ID = i.IDChoDau
    WHERE i.TrangThai IN (N'Đã hủy', N'Hoàn thành', N'Quá hạn')
      AND c.TrangThai = N'Đã đặt';
END;
GO

-- T3: Tự động tính tổng tiền Hóa đơn (ChiTietHoaDon -> Insert/Update/Delete)
IF OBJECT_ID('trg_ChiTietHD_TinhTongTien') IS NOT NULL DROP TRIGGER trg_ChiTietHD_TinhTongTien;
GO
CREATE TRIGGER trg_ChiTietHD_TinhTongTien
ON ChiTietHoaDon
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    -- Lấy danh sách các ID hóa đơn bị ảnh hưởng
    DECLARE @AffectedIDs TABLE (IDHoaDon INT);
    INSERT INTO @AffectedIDs SELECT IDHoaDon FROM Inserted
    UNION SELECT IDHoaDon FROM Deleted;

    -- Tính lại tổng tiền
    UPDATE HoaDon
    SET ThanhTien = (
        SELECT ISNULL(SUM(TongTien), 0)
        FROM ChiTietHoaDon
        WHERE ChiTietHoaDon.IDHoaDon = HoaDon.ID
    )
    WHERE ID IN (SELECT IDHoaDon FROM @AffectedIDs);
END;
GO

-- T4: Ngăn chặn đặt trùng lịch (DatCho -> Insert/Update)
IF OBJECT_ID('trg_DatCho_CheckTrungLich') IS NOT NULL DROP TRIGGER trg_DatCho_CheckTrungLich;
GO
CREATE TRIGGER trg_DatCho_CheckTrungLich
ON DatCho
AFTER INSERT, UPDATE
AS
BEGIN
    IF EXISTS (
        SELECT 1
        FROM DatCho d
        JOIN Inserted i ON d.IDChoDau = i.IDChoDau
        WHERE d.ID <> i.ID -- Không so sánh với chính nó
          AND d.TrangThai NOT IN (N'Đã hủy')
          -- Logic trùng giờ: (A_Start < B_End) AND (A_End > B_Start)
          AND (d.TgianBatDau < i.TgianKetThuc AND d.TgianKetThuc > i.TgianBatDau)
    )
    BEGIN
        ROLLBACK TRANSACTION;
        RAISERROR (N'Lỗi: Chỗ đậu xe này đã có người đặt trong khung giờ này!', 16, 1);
        RETURN;
    END
END;
GO

-- T5: Xử lý Voucher (HoaDon -> Insert)
IF OBJECT_ID('trg_HoaDon_XuLyVoucher') IS NOT NULL DROP TRIGGER trg_HoaDon_XuLyVoucher;
GO
CREATE TRIGGER trg_HoaDon_XuLyVoucher
ON HoaDon
AFTER INSERT
AS
BEGIN
    IF EXISTS (SELECT 1 FROM inserted WHERE IDVoucher IS NOT NULL)
    BEGIN
        -- Kiểm tra Voucher có hợp lệ không
        IF EXISTS (
            SELECT 1
            FROM Voucher v JOIN inserted i ON v.ID = i.IDVoucher
            WHERE v.SoLuong <= 0 OR v.HanSuDung < GETDATE()
        )
        BEGIN
            ROLLBACK TRANSACTION;
            RAISERROR (N'Lỗi: Voucher đã hết hạn hoặc hết số lượng!', 16, 1);
            RETURN;
        END

        -- Trừ số lượng Voucher
        UPDATE Voucher
        SET SoLuong = SoLuong - 1
        FROM Voucher v JOIN inserted i ON v.ID = i.IDVoucher;
    END
END;
GO

-- T6: Kiểm tra Thẻ xe tháng (TheXeThang -> Insert/Update)
IF OBJECT_ID('trg_TheXeThang_Validate') IS NOT NULL DROP TRIGGER trg_TheXeThang_Validate;
GO
CREATE TRIGGER trg_TheXeThang_Validate
ON TheXeThang
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Kiểm tra logic ngày tháng
    IF EXISTS (SELECT 1 FROM inserted WHERE NgayHetHan <= NgayDangKy)
    BEGIN
        RAISERROR(N'Lỗi: Ngày hết hạn phải lớn hơn ngày đăng ký.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END

    -- Tự động kích hoạt lại thẻ nếu gia hạn
    IF UPDATE(NgayHetHan)
    BEGIN
        UPDATE TheXeThang
        SET TrangThai = 1
        FROM TheXeThang t
        JOIN inserted i ON t.ID = i.ID
        WHERE i.NgayHetHan > GETDATE() AND i.TrangThai = 0;
    END
END;
GO

-- T7: Cập nhật trạng thái chỗ khi XE VÀO/RA/ĐỔI CHỖ (PhieuGiuXe)
IF OBJECT_ID('trg_PhieuGiuXe_CapNhatTrangThai') IS NOT NULL DROP TRIGGER trg_PhieuGiuXe_CapNhatTrangThai;
GO
CREATE TRIGGER trg_PhieuGiuXe_CapNhatTrangThai
ON PhieuGiuXe
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- TRƯỜNG HỢP 1: XE VÀO (INSERT) -> Đang đỗ
    IF EXISTS (SELECT * FROM inserted) AND NOT EXISTS (SELECT * FROM deleted)
    BEGIN
        UPDATE ChoDauXe
        SET TrangThai = N'Đang đỗ'
        FROM ChoDauXe c
        JOIN inserted i ON c.ID = i.IDChoDau;
    END

    -- TRƯỜNG HỢP 2: XE RA (UPDATE TgianRa) -> Trống
    IF UPDATE(TgianRa)
    BEGIN
        UPDATE ChoDauXe
        SET TrangThai = N'Trống'
        FROM ChoDauXe c
        JOIN inserted i ON c.ID = i.IDChoDau
        WHERE i.TgianRa IS NOT NULL;
    END
    
    -- TRƯỜNG HỢP 3: ĐỔI CHỖ (UPDATE IDChoDau) -> Cập nhật cả chỗ cũ và mới
    IF UPDATE(IDChoDau)
    BEGIN
        -- Chỗ cũ thành Trống
        UPDATE ChoDauXe SET TrangThai = N'Trống'
        FROM ChoDauXe c JOIN deleted d ON c.ID = d.IDChoDau;

        -- Chỗ mới thành Đang đỗ
        UPDATE ChoDauXe SET TrangThai = N'Đang đỗ'
        FROM ChoDauXe c JOIN inserted i ON c.ID = i.IDChoDau;
    END
END;
GO