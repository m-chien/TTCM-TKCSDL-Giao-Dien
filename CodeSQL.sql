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
    CCCD VARCHAR(20) UNIQUE,
    BangLaiXe VARCHAR(20) UNIQUE,
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
    IDKhachHang INT CONSTRAINT FK_KHXe_KhachHang FOREIGN KEY REFERENCES KhachHang(ID) 
            ON UPDATE NO ACTION 
            ON DELETE NO ACTION, 
    IDXe VARCHAR(20) CONSTRAINT FK_KHXe_Xe FOREIGN KEY REFERENCES Xe(BienSoXe) 
            ON UPDATE CASCADE 
            ON DELETE CASCADE,
    CONSTRAINT PK_KhachHang_Xe PRIMARY KEY (IDKhachHang, IDXe),
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
    IDKhachHang INT NOT NULL,
    IDXe VARCHAR(20) NOT NULL,
    TenTheXe NVARCHAR(100),
    NgayDangKy DATE DEFAULT GETDATE(),
    NgayHetHan DATE NOT NULL,
    TrangThai BIT DEFAULT 1,

    -- Ràng buộc đồng bộ: Nếu IDXe thay đổi hoặc Khách hàng bị xóa, thẻ sẽ tự cập nhật/xóa theo
    CONSTRAINT FK_TheXe_KHXe FOREIGN KEY (IDKhachHang, IDXe) 
        REFERENCES KhachHang_Xe(IDKhachHang, IDXe) 
        ON UPDATE CASCADE 
        ON DELETE CASCADE
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
    IDKhachHang INT NOT NULL,
    IDXe VARCHAR(20) NOT NULL,
    IDChoDau INT NOT NULL,
    IDNhanVien INT,
    TgianBatDau DATETIME,
    TgianKetThuc DATETIME,
    TrangThai NVARCHAR(50) CONSTRAINT CK_DatCho_TrangThai 
        CHECK (TrangThai IN (N'Đã đặt', N'Đã hủy', N'Hoàn thành', N'Quá hạn')),

    -- Ràng buộc tham chiếu cặp Khách-Xe
    CONSTRAINT FK_DatCho_KHXe FOREIGN KEY (IDKhachHang, IDXe) 
        REFERENCES KhachHang_Xe(IDKhachHang, IDXe) 
        ON UPDATE CASCADE 
        ON DELETE CASCADE,

    CONSTRAINT FK_DatCho_NhanVien FOREIGN KEY (IDNhanVien) REFERENCES NhanVien(ID) 
        ON UPDATE NO ACTION ON DELETE NO ACTION,
        
    CONSTRAINT FK_DatCho_ChoDau FOREIGN KEY (IDChoDau) REFERENCES ChoDauXe(ID) 
        ON UPDATE NO ACTION ON DELETE NO ACTION
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
    IDKhachHang INT NOT NULL,
    IDXe VARCHAR(20) NOT NULL,
    IDChoDau INT NOT NULL,
    IDNhanVienVao INT,
    IDNhanVienRa INT,
    IDHoaDon INT,
    TgianVao DATETIME DEFAULT GETDATE(),
    TgianRa DATETIME,
    TrangThai NVARCHAR(50) CONSTRAINT CK_PhieuGiuXe_TrangThai 
        CHECK (TrangThai IN (N'Đang gửi', N'Đã lấy', N'Quá hạn', N'Mất vé')),

    CONSTRAINT FK_PGX_KHXe FOREIGN KEY (IDKhachHang, IDXe) 
        REFERENCES KhachHang_Xe(IDKhachHang, IDXe) 
        ON UPDATE CASCADE 
        ON DELETE CASCADE,

    CONSTRAINT FK_PGX_ChoDau FOREIGN KEY (IDChoDau) REFERENCES ChoDauXe(ID) 
        ON UPDATE NO ACTION ON DELETE NO ACTION,
        
    CONSTRAINT FK_PGX_NVVao FOREIGN KEY (IDNhanVienVao) REFERENCES NhanVien(ID) 
        ON UPDATE NO ACTION ON DELETE NO ACTION,
        
    CONSTRAINT FK_PGX_NVRa FOREIGN KEY (IDNhanVienRa) REFERENCES NhanVien(ID) 
        ON UPDATE NO ACTION ON DELETE NO ACTION,
        
    CONSTRAINT FK_PGX_HoaDon FOREIGN KEY (IDHoaDon) REFERENCES HoaDon(ID) 
        ON UPDATE NO ACTION ON DELETE NO ACTION
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

-- 1. DANH MỤC CƠ BẢN
INSERT INTO VaiTro (TenVaiTro) VALUES (N'Admin'), (N'Nhân viên'), (N'Khách hàng'), (N'Chủ bãi xe');
INSERT INTO LoaiXe (TenLoaiXe) VALUES (N'Xe Máy'), (N'Ô tô 4 chỗ'), (N'Ô tô 7 chỗ'), (N'Xe Tải nhỏ');
INSERT INTO CaLam (TenCa, TgianBatDau, TgianKetThuc, HeSoLuong) VALUES 
(N'Ca Sáng', '06:00', '14:00', 1.0), 
(N'Ca Chiều', '14:00', '22:00', 1.0);

-- 2. HỆ THỐNG TÀI KHOẢN
INSERT INTO TaiKhoan (IDVaiTro, TenDangNhap, MatKhau) VALUES 
(1, 'admin', '123456'), 
(2, 'nv_bao', '123456'), 
(3, 'kh_tung', '123456'), 
(3, 'kh_hoa', '123456'), 
(4, 'chu_hung', '123456');

-- 3. THÔNG TIN CHI TIẾT NGƯỜI DÙNG
INSERT INTO NhanVien (IDTaiKhoan, TenNhanVien, SDT, Email, ChucVu, LuongCB) 
VALUES (2, N'Nguyễn Văn Bảo', '0901234567', 'bao@parking.com', N'Bảo vệ', 7000000);

INSERT INTO KhachHang (IDTaiKhoan, HoTen, SDT, CCCD, BangLaiXe, DiaChi, LoaiKH) VALUES 
(3, N'Phạm Thanh Tùng', '0912345678', '001090000001', 'B1-123456', N'Hà Nội', N'Thường xuyên'),
(4, N'Lê Thị Hoa', '0987654321', '001090000002', 'B2-987654', N'Đà Nẵng', N'Vãng lai');

INSERT INTO ChuBaiXe (IDTaiKhoan, TenChuBai, SDT, Email, CCCD, DiaChi) 
VALUES (5, N'Trần Văn Hùng', '0999888777', 'hung@owner.com', '001090999999', N'TP HCM');

-- 4. XE & THIẾT LẬP SỞ HỮU 
INSERT INTO Xe (BienSoXe, IDLoaiXe, TenXe, Hang, MauSac) VALUES 
('30A-123.45', 2, 'Vios', 'Toyota', N'Trắng'),
('29H-999.99', 1, 'SH 150i', 'Honda', N'Đen'),
('43A-567.89', 3, 'CX-5', 'Mazda', N'Đỏ');

INSERT INTO KhachHang_Xe (IDKhachHang, IDXe, LoaiSoHuu) VALUES 
(1, '30A-123.45', N'Chính chủ'), -- Tùng sở hữu Vios
(2, '43A-567.89', N'Thuê'),       -- Hoa sở hữu CX-5 (Thuê)
(1, '29H-999.99', N'Chính chủ'); -- Tùng sở hữu thêm SH

-- 5. CẤU TRÚC BÃI ĐỖ & THIẾT BỊ
INSERT INTO BaiDo (IDChuBai, TenBai, ViTri, SucChua, TrangThai) 
VALUES (1, N'Bãi xe Royal City', N'72A Nguyễn Trãi', 500, N'Hoạt động');

INSERT INTO KhuVuc (IDBaiDo, TenKhuVuc, SucChua) VALUES 
(1, N'Khu A - Ô tô', 200),
(1, N'Khu B - Xe máy', 300);

INSERT INTO ChoDauXe (IDKhuVuc, TenChoDau, KichThuoc, TrangThai) VALUES 
(1, 'A-01', N'5.0x2.5m', N'Đang đỗ'),
(1, 'A-02', N'5.0x2.5m', N'Trống'),
(1, 'A-03', N'5.0x2.5m', N'Trống'),
(2, 'B-01', N'2.0x1.0m', N'Trống'),
(2, 'B-02', N'2.0x1.0m', N'Đang đỗ');

INSERT INTO ThietBi (IDKhuVuc, TenThietBi, LoaiThietBi, TrangThai, NgayCaiDat, GiaLapDat) VALUES 
(1, N'Cam Cổng A1', N'Camera', N'Hoạt động', '2023-01-01', 5000000),
(1, N'Barrier A1', N'Barrier', N'Hoạt động', '2023-01-01', 15000000);

-- 6. GIÁ, VOUCHER & PHỤ TRỢ
INSERT INTO BangGia (IDBaiDo, IDLoaiXe, TenBangGia) VALUES 
(1, 2, N'Bảng giá Ô tô 2024'),
(1, 1, N'Bảng giá Xe máy 2024');

INSERT INTO LoaiHinhTinhPhi (IDBangGia, TenLoaiHinh, DonViThoiGian, GiaTien) VALUES 
(1, N'Vé lượt', N'Giờ', 20000),
(1, N'Vé tháng', N'Tháng', 1500000),
(2, N'Vé lượt', N'Giờ', 5000);

INSERT INTO Voucher (IDBaiDo, TenVoucher, GiaTri, HanSuDung, SoLuong, TrangThai, MaCode) VALUES 
(1, N'Giảm giá Tết', 10000, '2026-12-31', 50, 1, 'TET2026');

INSERT INTO LichLamViec (IDNhanVien, IDCaLam, IDBaiDo, NgayBatDau, NgayKetThuc, TrangThai, SoNgayDaLam) 
VALUES (1, 1, 1, '2026-01-01', '2026-01-31', 1, 4);

-- 7. NGHIỆP VỤ THỰC TẾ 
INSERT INTO TheXeThang (IDKhachHang, IDXe, TenTheXe, NgayDangKy, NgayHetHan, TrangThai) 
VALUES (1, '30A-123.45', N'Thẻ tháng Vios', '2026-01-01', '2026-01-31', 1);

INSERT INTO DatCho (IDKhachHang, IDXe, IDChoDau, IDNhanVien, TgianBatDau, TgianKetThuc, TrangThai) 
VALUES (2, '43A-567.89', 2, NULL, '2026-01-05 08:00', '2026-01-05 17:00', N'Đã đặt');

INSERT INTO HoaDon (ThanhTien, LoaiHoaDon, IDVoucher) VALUES (30000, N'Vé lượt', NULL);
INSERT INTO ThanhToan (IDHoaDon, PhuongThuc, TrangThai) VALUES (1, N'Tiền mặt', 1);

-- Phiếu giữ xe (Xe 1 đang gửi, xe 2 đã lấy)
INSERT INTO PhieuGiuXe (IDKhachHang, IDXe, IDChoDau, IDNhanVienVao, IDHoaDon, TgianVao, TrangThai) 
VALUES (1, '30A-123.45', 1, 1, NULL, GETDATE(), N'Đang gửi');

INSERT INTO PhieuGiuXe (IDKhachHang, IDXe, IDChoDau, IDNhanVienVao, IDNhanVienRa, IDHoaDon, TgianVao, TgianRa, TrangThai) 
VALUES (1, '29H-999.99', 4, 1, 1, 1, DATEADD(HOUR, -2, GETDATE()), GETDATE(), N'Đã lấy');

-- Chi tiết hóa đơn & Đánh giá
INSERT INTO ChiTietHoaDon (IDHoaDon, TongTien) VALUES (1, 30000);

INSERT INTO DanhGia (IDKhachHang, IDHoaDon, NoiDung, DiemDanhGia) 
VALUES (1, 1, N'Dịch vụ tốt', 5);

INSERT INTO SuCo (IDNhanVien, IDThietBi, MoTa, MucDo, TrangThaiXuLy) 
VALUES (1, 1, N'Màn hình hiển thị bị mờ', N'Nhẹ', N'Chưa xử lý');
GO
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
    LEFT JOIN PhieuGiuXe pgx ON (x.BienSoXe = pgx.IDXe AND kh.ID = pgx.IDKhachHang)
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
    FROM ChoDauXe c 
    JOIN inserted i ON c.ID = i.IDChoDau;
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
        UPDATE ChoDauXe 
        SET TrangThai = N'Đang đỗ' 
        FROM ChoDauXe c JOIN inserted i ON c.ID = i.IDChoDau;
     -- Xe ra: Chuyển sang Trống
    IF UPDATE(TgianRa)
        UPDATE ChoDauXe 
        SET TrangThai = N'Trống' 
        FROM ChoDauXe c JOIN inserted i ON c.ID = i.IDChoDau 
        WHERE i.TgianRa IS NOT NULL;
     -- Đổi chỗ
    IF UPDATE(IDChoDau) BEGIN
        UPDATE ChoDauXe 
        SET TrangThai = N'Trống' 
        FROM ChoDauXe c JOIN deleted d ON c.ID = d.IDChoDau;

        UPDATE ChoDauXe 
        SET TrangThai = N'Đang đỗ' 
        FROM ChoDauXe c JOIN inserted i ON c.ID = i.IDChoDau;
    END
END;


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


--Thêm Tài khoản Khách hàng 
IF OBJECT_ID('sp_ThemTaiKhoanKhachHang') IS NOT NULL DROP PROCEDURE sp_ThemTaiKhoanKhachHang;
GO
CREATE PROCEDURE sp_ThemTaiKhoanKhachHang
    @TenDangNhap VARCHAR(50), @MatKhau VARCHAR(255), @HoTen NVARCHAR(100), 
    @SDT VARCHAR(11), @CCCD VARCHAR(20), @DiaChi NVARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
            INSERT INTO TaiKhoan (IDVaiTro, TenDangNhap, MatKhau) VALUES (3, @TenDangNhap, @MatKhau);
            DECLARE @IDTK INT = SCOPE_IDENTITY();
            INSERT INTO KhachHang (IDTaiKhoan, HoTen, SDT, CCCD, DiaChi, LoaiKH)
            VALUES (@IDTK, @HoTen, @SDT, @CCCD, @DiaChi, N'Vãng lai');
            SELECT @IDTK AS IDTaiKhoan, SCOPE_IDENTITY() AS IDKhachHang;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION; THROW;
    END CATCH
END;
GO


-- Thêm Xe và Liên kết với Khách hàng
IF OBJECT_ID('sp_ThemXeKhachHang') IS NOT NULL DROP PROCEDURE sp_ThemXeKhachHang;
GO
CREATE PROCEDURE sp_ThemXeKhachHang
    @IDKhachHang INT, @BienSoXe VARCHAR(20), @IDLoaiXe INT, @TenXe NVARCHAR(100), 
    @Hang NVARCHAR(50), @MauSac NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM Xe WHERE BienSoXe = @BienSoXe)
        INSERT INTO Xe (BienSoXe, IDLoaiXe, TenXe, Hang, MauSac) VALUES (@BienSoXe, @IDLoaiXe, @TenXe, @Hang, @MauSac);
    INSERT INTO KhachHang_Xe (IDKhachHang, IDXe, LoaiSoHuu) VALUES (@IDKhachHang, @BienSoXe, N'Chính chủ');
END;
GO

-- Khách hàng đặt chỗ
IF OBJECT_ID('sp_KhachHangDatCho') IS NOT NULL DROP PROCEDURE sp_KhachHangDatCho;
GO
CREATE PROCEDURE sp_KhachHangDatCho
    @IDKhachHang INT,
    @BienSoXe VARCHAR(20),
    @IDChoDau INT,
    @TgianBatDau DATETIME,
    @TgianKetThuc DATETIME
AS
BEGIN
    SET NOCOUNT ON;
    -- Kiểm tra xem xe này có thuộc quyền sở hữu của khách hàng không
    IF NOT EXISTS (SELECT 1 FROM KhachHang_Xe WHERE IDKhachHang = @IDKhachHang AND IDXe = @BienSoXe)
    BEGIN
        RAISERROR(N'Lỗi: Xe này chưa được đăng ký dưới tên khách hàng này!', 16, 1);
        RETURN;
    END

    INSERT INTO DatCho (IDKhachHang, IDXe, IDChoDau, TgianBatDau, TgianKetThuc, TrangThai)
    VALUES (@IDKhachHang, @BienSoXe, @IDChoDau, @TgianBatDau, @TgianKetThuc, N'Đã đặt');
    
    PRINT N'Đặt chỗ thành công cho xe ' + @BienSoXe;
END;
GO
GO


-- Nhân viên duyệt
IF OBJECT_ID('sp_NhanVienDuyetDatCho') IS NOT NULL DROP PROCEDURE sp_NhanVienDuyetDatCho;
GO
CREATE PROCEDURE sp_NhanVienDuyetDatCho
    @IDDatCho INT,
    @IDNhanVien INT,
    @TrangThaiMoi NVARCHAR(50) -- 'Hoàn thành' hoặc 'Đã hủy'
AS
BEGIN
    UPDATE DatCho
    SET TrangThai = @TrangThaiMoi,
        IDNhanVien = @IDNhanVien
    WHERE ID = @IDDatCho;
    -- Lưu ý: Trigger trg_DatCho_GiaiPhongCho sẽ tự động trả chỗ về 'Trống' nếu trạng thái là Hoàn thành/Hủy
    PRINT N'Đã duyệt trạng thái đặt chỗ.';
END;
GO


-- Xem tất cả xe của một khách hàng cụ thể
IF OBJECT_ID('sp_XemXeCuaKhachHang') IS NOT NULL DROP PROCEDURE sp_XemXeCuaKhachHang;
GO
CREATE PROCEDURE sp_XemXeCuaKhachHang @IDKhachHang INT
AS
BEGIN
    SELECT kh.HoTen, x.BienSoXe, lx.TenLoaiXe, x.TenXe, x.MauSac
    FROM KhachHang kh
    JOIN KhachHang_Xe khx ON kh.ID = khx.IDKhachHang
    JOIN Xe x ON khx.IDXe = x.BienSoXe
    JOIN LoaiXe lx ON x.IDLoaiXe = lx.ID
    WHERE kh.ID = @IDKhachHang;
END;
GO

-- Thống kê danh sách đặt chỗ đang chờ duyệt (Trạng thái 'Đã đặt')
IF OBJECT_ID('sp_DanhSachChoDuyet') IS NOT NULL DROP PROCEDURE sp_DanhSachChoDuyet;
GO
CREATE PROCEDURE sp_DanhSachChoDuyet
AS
BEGIN
    SELECT dc.ID AS IDDatCho, kh.HoTen, kh.SDT, cd.TenChoDau, dc.TgianBatDau, dc.TgianKetThuc
    FROM DatCho dc
    JOIN KhachHang kh ON dc.IDKhachHang = kh.ID
    JOIN ChoDauXe cd ON dc.IDChoDau = cd.ID
    WHERE dc.TrangThai = N'Đã đặt'
    ORDER BY dc.TgianBatDau ASC;
END;
GO


-- Bước 1: Thêm tài khoản
EXEC sp_ThemTaiKhoanKhachHang 'tung_nguyen_2', '123', N'Nguyễn Thanh Tùng', '0911222444', '123123555', N'Hà Nội';
-- Bước 2: Thêm xe cho khách hàng vừa tạo (Giả sử ID khách hàng là 3)
EXEC sp_ThemXeKhachHang 3, '30A-888.88', 2, 'Civic', 'Honda', N'Trắng';
-- Bước 3: Khách hàng đặt chỗ A-01 (ID = 1)
EXEC sp_KhachHangDatCho 3, '30A-888.88', 1, '2026-06-01 08:00', '2026-06-01 17:00';
-- Kiểm tra trạng thái chỗ đậu (Sẽ tự động chuyển sang 'Đã đặt' nhờ Trigger)
SELECT TenChoDau, TrangThai FROM ChoDauXe WHERE ID = 1;
-- Xem danh sách các yêu cầu đang chờ duyệt
EXEC sp_DanhSachChoDuyet;
EXEC sp_NhanVienDuyetDatCho 2, 1, N'Hoàn thành';
-- Bước 4: Nhân viên (ID = 1) xem danh sách và duyệt
-- Kiểm tra lại: Sau khi duyệt 'Hoàn thành', chỗ đậu sẽ tự động trả về 'Trống' 
SELECT TenChoDau, TrangThai 
FROM ChoDauXe WHERE ID = 1;


-- Thủ tục Xe vào bãi
IF OBJECT_ID('sp_XeVaoBai') IS NOT NULL DROP PROCEDURE sp_XeVaoBai;
GO
CREATE PROCEDURE sp_XeVaoBai
    @IDKhachHang INT, @BienSoXe VARCHAR(20), @IDChoDau INT, @IDNhanVien INT
AS
BEGIN
    INSERT INTO PhieuGiuXe (IDKhachHang, IDXe, IDChoDau, IDNhanVienVao, TgianVao, TrangThai)
    VALUES (@IDKhachHang, @BienSoXe, @IDChoDau, @IDNhanVien, GETDATE(), N'Đang gửi');

     PRINT N'Xe đã vào bãi thành công.';
END;


-- Thủ tục Xe ra bãi
IF OBJECT_ID('sp_XeRaBai') IS NOT NULL DROP PROCEDURE sp_XeRaBai;
GO
CREATE PROCEDURE sp_XeRaBai
    @IDPhieuGiuXe INT,
    @IDNhanVienRa INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
            
            -- 1. Kiểm tra xem phiếu có tồn tại và xe đã ra chưa
            IF NOT EXISTS (SELECT 1 FROM PhieuGiuXe WHERE ID = @IDPhieuGiuXe AND TgianRa IS NULL)
            BEGIN
                RAISERROR(N'Lỗi: Phiếu giữ xe không tồn tại hoặc xe đã ra bãi trước đó.', 16, 1);
                ROLLBACK TRANSACTION;
                RETURN;
            END

            -- 2. Cập nhật thời gian ra, ID nhân viên xử lý và trạng thái
            -- Khi lệnh UPDATE này chạy, Trigger trg_PhieuGiuXe_TinhTien sẽ tự động:
            --   - Tính số giờ đỗ.
            --   - Kiểm tra thẻ tháng (nếu có thì tiền = 0).
            --   - Tạo Hóa đơn & Chi tiết hóa đơn.
            --   - Cập nhật IDHoaDon ngược lại vào PhieuGiuXe.
            -- Trigger trg_PhieuGiuXe_CapNhatTrangThai sẽ tự động:
            --   - Chuyển trạng thái chỗ đỗ sang 'Trống'.
            
            UPDATE PhieuGiuXe 
            SET TgianRa = GETDATE(),
                IDNhanVienRa = @IDNhanVienRa,
                TrangThai = N'Đã lấy'
            WHERE ID = @IDPhieuGiuXe;
            
            PRINT N'Xe đã ra bãi thành công. Hóa đơn đã được hệ thống tự động khởi tạo.';
            
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH
END;
GO


-- Trigger Tự động Tính tiền & Tạo Hóa đơn
IF OBJECT_ID('trg_PhieuGiuXe_TinhTien') IS NOT NULL DROP TRIGGER trg_PhieuGiuXe_TinhTien;
GO
CREATE TRIGGER trg_PhieuGiuXe_TinhTien
ON PhieuGiuXe
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    IF UPDATE(TgianRa)
    BEGIN
        DECLARE @IDPhieu INT, @IDKH INT, @BienSo VARCHAR(20), 
                @Vao DATETIME, @Ra DATETIME, @IDLoaiXe INT, @IDBaiDo INT;
        DECLARE @SoGio INT, @DonGia DECIMAL(18,2), @TongTien DECIMAL(18,2);

        SELECT 
            @IDPhieu = i.ID, 
            @IDKH = i.IDKhachHang, 
            @BienSo = i.IDXe, 
            @Vao = i.TgianVao, 
            @Ra = i.TgianRa, 
            @IDLoaiXe = x.IDLoaiXe,
            @IDBaiDo = kv.IDBaiDo
        FROM inserted i
        JOIN Xe x ON i.IDXe = x.BienSoXe
        JOIN ChoDauXe cd ON i.IDChoDau = cd.ID
        JOIN KhuVuc kv ON cd.IDKhuVuc = kv.ID
        WHERE i.TgianRa IS NOT NULL;

        IF @IDPhieu IS NULL RETURN;

        -- 1. KIỂM TRA THẺ XE THÁNG (Ưu tiên số 1)
        -- Nếu cặp Khách - Xe này có thẻ tháng còn hạn, tổng tiền sẽ là 0
        IF EXISTS (
            SELECT 1 FROM TheXeThang 
            WHERE IDKhachHang = @IDKH 
              AND IDXe = @BienSo 
              AND TrangThai = 1 
              AND NgayHetHan >= CAST(@Ra AS DATE)
        )
        BEGIN
            SET @TongTien = 0;
        END
        ELSE
        BEGIN
            -- 2. TÍNH TIỀN THEO GIỜ (Dành cho khách vãng lai hoặc hết hạn thẻ)
            -- Tính số giờ: DATEDIFF lấy phút / 60 và làm tròn lên (CEILING)
            SET @SoGio = CEILING(CAST(DATEDIFF(MINUTE, @Vao, @Ra) AS FLOAT) / 60.0);
            
            -- Đảm bảo tối thiểu tính 1 giờ
            IF @SoGio <= 0 SET @SoGio = 1;

            -- Lấy đơn giá từ bảng giá tương ứng với Bãi đó và Loại xe đó
            SELECT TOP 1 @DonGia = lhtp.GiaTien
            FROM BangGia bg
            JOIN LoaiHinhTinhPhi lhtp ON bg.ID = lhtp.IDBangGia
            WHERE bg.IDBaiDo = @IDBaiDo 
              AND bg.IDLoaiXe = @IDLoaiXe 
              AND lhtp.DonViThoiGian = N'Giờ'
              AND bg.HieuLuc = 1
            ORDER BY bg.ID DESC;

            -- Nếu không tìm thấy bảng giá, mặc định lấy 5000 để tránh lỗi logic
            SET @DonGia = ISNULL(@DonGia, 5000);
            SET @TongTien = @SoGio * @DonGia;
        END

        -- 3. TẠO HÓA ĐƠN
        INSERT INTO HoaDon (ThanhTien, NgayTao, LoaiHoaDon)
        VALUES (@TongTien, GETDATE(), N'Vé lượt');
        
        DECLARE @NewHoaDonID INT = SCOPE_IDENTITY();

        -- 4. CẬP NHẬT NGƯỢC LẠI PHIẾU GIỮ XE
        UPDATE PhieuGiuXe 
        SET IDHoaDon = @NewHoaDonID 
        WHERE ID = @IDPhieu;

        -- 5. TẠO CHI TIẾT HÓA ĐƠN
        INSERT INTO ChiTietHoaDon (IDHoaDon, TongTien) 
        VALUES (@NewHoaDonID, @TongTien);
    END
END;
GO


-- Thống kê Doanh thu theo ngày
IF OBJECT_ID('sp_ThongKeDoanhThuTheoNgay') IS NOT NULL DROP PROCEDURE sp_ThongKeDoanhThuTheoNgay;
GO
CREATE PROCEDURE sp_ThongKeDoanhThuTheoNgay
    @Ngay DATE
AS
BEGIN
    SELECT 
        COUNT(ID) AS SoLuotXe,
        SUM(ThanhTien) AS TongDoanhThu,
        AVG(ThanhTien) AS TrungBinhMoiLuot
    FROM HoaDon
    WHERE CAST(NgayTao AS DATE) = @Ngay;
END;
GO


-- 1. Cho xe vào bãi
EXEC sp_XeVaoBai 1, '30A-123.45', 1, 1;

-- Kiểm tra trạng thái chỗ đậu (Sẽ tự động chuyển sang 'Đang đỗ')
SELECT TenChoDau, TrangThai FROM ChoDauXe WHERE ID = 1;

-- Kiểm tra phiếu giữ xe vừa tạo
SELECT * FROM PhieuGiuXe WHERE IDXe = '30A-123.45' AND TgianRa IS NULL;

-- 2. Giả lập xe đã đỗ được 3 tiếng
UPDATE PhieuGiuXe 
SET TgianVao = DATEADD(HOUR, -3, GETDATE()) 
WHERE IDXe = '30A-123.45' AND TgianRa IS NULL;

-- 3. Cho xe ra bãi (Lấy ID phiếu mới nhất của xe này)
EXEC sp_XeRaBai 1, 1;

-- 4. Kiểm tra kết quả
SELECT h.*, pgx.IDXe, pgx.TgianVao, pgx.TgianRa 
FROM HoaDon h
JOIN PhieuGiuXe pgx ON h.ID = pgx.IDHoaDon
WHERE pgx.IDXe = '30A-123.45';

-- 5. Kiểm tra trạng thái chỗ đậu (Phải trở về 'Trống')
SELECT TenChoDau, TrangThai FROM ChoDauXe WHERE ID = 1;