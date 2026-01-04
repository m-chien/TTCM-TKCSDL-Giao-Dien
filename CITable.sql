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