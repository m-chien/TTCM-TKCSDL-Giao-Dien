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
    IDVaiTro VARCHAR(10) PRIMARY KEY , --VT01_NV(Vai trò 01,Nhân viên)
    TenVaiTro NVARCHAR(50) NOT NULL
);

CREATE TABLE LoaiXe (
    IDLoaiXe VARCHAR(10) PRIMARY KEY , --LX01_O4(Loại xe 01,Ô tô 4 chỗ)
    TenLoaiXe NVARCHAR(50) NOT NULL
);

CREATE TABLE CaLam (
    IDCaLam VARCHAR(8) PRIMARY KEY ,-- CL01_S(Ca làm 01,Sáng)
    TenCa NVARCHAR(50),
    TgianBatDau TIME,
    TgianKetThuc TIME,
    HeSoLuong FLOAT
);

-- 2. HỆ THỐNG TÀI KHOẢN
CREATE TABLE TaiKhoan (
    IDTaiKhoan VARCHAR(15) PRIMARY KEY ,--TK00001_KH(Tài khoản 00001,Khách hàng)
    IDVaiTroNo VARCHAR(10) CONSTRAINT FK_TaiKhoan_VaiTro FOREIGN KEY REFERENCES VaiTro(IDVaiTro) 
            ON UPDATE CASCADE 
            ON DELETE CASCADE,
    TenDangNhap VARCHAR(50) UNIQUE NOT NULL,
    MatKhau VARCHAR(255) NOT NULL,
    AnhDaiDien VARCHAR(255),
    TrangThai BIT DEFAULT 1
);

CREATE TABLE NhanVien (
    IDNhanVien VARCHAR(10) PRIMARY KEY ,--NV001_BV(Nhân viên 001,Bảo vệ)
    IDTaiKhoanNo VARCHAR(15) CONSTRAINT FK_NhanVien_TaiKhoan FOREIGN KEY REFERENCES TaiKhoan(IDTaiKhoan) 
            ON UPDATE CASCADE 
            ON DELETE CASCADE,
    TenNhanVien NVARCHAR(100),
    SDT VARCHAR(11) CONSTRAINT CK_NhanVien_SDT CHECK (SDT NOT LIKE '%[^0-9]%' AND LEN(SDT) >= 10),
    Email VARCHAR(100) CONSTRAINT CK_NhanVien_Email CHECK (Email LIKE '%_@__%.__%'),
    ChucVu NVARCHAR(50),
    LuongCB DECIMAL(18,2)
);

CREATE TABLE KhachHang (
    IDKhachHang VARCHAR(12) PRIMARY KEY ,--KH00001_VI(Khách hàng 00001,VIP)
    IDTaiKhoanNo VARCHAR(15) CONSTRAINT FK_KhachHang_TaiKhoan FOREIGN KEY REFERENCES TaiKhoan(IDTaiKhoan) 
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
    IDChuBaiXe VARCHAR(8) PRIMARY KEY ,--CB001(Chủ bãi xe 001)
    IDTaiKhoanNo VARCHAR(15) CONSTRAINT FK_ChuBaiXe_TaiKhoan FOREIGN KEY REFERENCES TaiKhoan(IDTaiKhoan) 
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
    BienSoXe VARCHAR(12) PRIMARY KEY,
    IDLoaiXeNo VARCHAR(10) CONSTRAINT FK_Xe_LoaiXe FOREIGN KEY REFERENCES LoaiXe(IDLoaiXe)  
            ON UPDATE CASCADE 
            ON DELETE CASCADE,
    TenXe NVARCHAR(100),
    Hang NVARCHAR(50),
    MauSac NVARCHAR(50),
    HinhAnh NVARCHAR(255)
);

CREATE TABLE KhachHang_Xe (
    IDKhachHangNo VARCHAR(12) CONSTRAINT FK_KHXe_KhachHang FOREIGN KEY REFERENCES KhachHang(IDKhachHang) 
            ON UPDATE NO ACTION 
            ON DELETE NO ACTION, 
    IDXeNo VARCHAR(12) CONSTRAINT FK_KHXe_Xe FOREIGN KEY REFERENCES Xe(BienSoXe) 
            ON UPDATE CASCADE 
            ON DELETE CASCADE,
    CONSTRAINT PK_KhachHang_Xe PRIMARY KEY (IDKhachHangNo, IDXeNo),
    LoaiSoHuu NVARCHAR(50)
);

-- 4. CẤU TRÚC BÃI ĐỖ
CREATE TABLE BaiDo (
    IDBaiDo VARCHAR(8) PRIMARY KEY ,--BD001(Bãi đỗ 001)
    IDChuBaiNo VARCHAR(8) CONSTRAINT FK_BaiDo_ChuBai FOREIGN KEY REFERENCES ChuBaiXe(IDChuBaiXe) 
            ON UPDATE CASCADE 
            ON DELETE CASCADE,
    TenBai NVARCHAR(100),
    ViTri NVARCHAR(255),
    SucChua INT,
    TrangThai NVARCHAR(50) CONSTRAINT CK_BaiDo_TrangThai CHECK (TrangThai IN (N'Hoạt động', N'Đóng cửa', N'Bảo trì', N'Tạm dừng')),
    HinhAnh NVARCHAR(255)
);

CREATE TABLE KhuVuc (
    IDKhuVuc VARCHAR(10) PRIMARY KEY ,--KV001_A(Khu vực 001,A là tên khu(A,B,C,D) hoặc tầng hầm là TH)
    IDBaiDoNo VARCHAR(8) CONSTRAINT FK_KhuVuc_BaiDo FOREIGN KEY REFERENCES BaiDo(IDBaiDo) 
            ON UPDATE CASCADE 
            ON DELETE CASCADE,
    TenKhuVuc NVARCHAR(50),
    SucChua INT,
    HinhAnh VARCHAR(255)
);

CREATE TABLE ChoDauXe (
    IDChoDauXe VARCHAR(12) PRIMARY KEY ,--CD0001_A(Chỗ đậu 0001,A là khu vực )
    IDKhuVucNo VARCHAR(10) CONSTRAINT FK_ChoDau_KhuVuc FOREIGN KEY REFERENCES KhuVuc(IDKhuVuc) 
            ON UPDATE CASCADE 
            ON DELETE CASCADE,
    TenChoDau NVARCHAR(20),
    KichThuoc VARCHAR(50),
    TrangThai NVARCHAR(50) CONSTRAINT CK_ChoDauXe_TrangThai CHECK (TrangThai IN (N'Trống', N'Đã đặt', N'Đang đỗ', N'Bảo trì'))
);

CREATE TABLE ThietBi (
    IDThietBi VARCHAR(10) PRIMARY KEY, --TB001_CA(Thiết bị 001,CA là Camera)
    IDKhuVucNo VARCHAR(10) CONSTRAINT FK_ThietBi_KhuVuc FOREIGN KEY REFERENCES KhuVuc(IDKhuVuc) 
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
    IDBangGia VARCHAR(10) PRIMARY KEY ,--BG001_O4(Bảng giá 001,Ô tô 4 chỗ)
    IDBaiDoNo VARCHAR(8) CONSTRAINT FK_BangGia_BaiDo FOREIGN KEY REFERENCES BaiDo(IDBaiDo) 
            ON UPDATE CASCADE 
            ON DELETE CASCADE,
    IDLoaiXeNo VARCHAR(10) CONSTRAINT FK_BangGia_LoaiXe FOREIGN KEY REFERENCES LoaiXe(IDLoaiXe) 
            ON UPDATE CASCADE 
            ON DELETE NO ACTION,
    TenBangGia NVARCHAR(100),
    HieuLuc BIT DEFAULT 1
);

CREATE TABLE LoaiHinhTinhPhi (
    IDLoaiHinhTinhPhi VARCHAR(15) PRIMARY KEY ,--LH001_GIO_O4(Loại hình 001,Theo giờ,Ô tô 4 chỗ)
    IDBangGiaNo VARCHAR(10) CONSTRAINT FK_LHTP_BangGia FOREIGN KEY REFERENCES BangGia(IDBangGia) 
            ON UPDATE CASCADE 
            ON DELETE CASCADE,
    TenLoaiHinh NVARCHAR(100),
    DonViThoiGian NVARCHAR(50) CONSTRAINT CK_LoaiHinhTinhPhi_DonViThoiGian CHECK(DonViThoiGian IN (N'Giờ',N'Ngày',N'Tháng',N'Năm')),
    GiaTien DECIMAL(18,2) NOT NULL
);

CREATE TABLE KhungGio (
    IDKhungGio VARCHAR(10) PRIMARY KEY,--KG01_HC(Khung giờ 01,Hành chính)
    IDLoaiHinhTinhPhiNo VARCHAR(15) CONSTRAINT FK_KhungGio_LHTP FOREIGN KEY REFERENCES LoaiHinhTinhPhi(IDLoaiHinhTinhPhi) 
            ON UPDATE CASCADE 
            ON DELETE CASCADE,
    TenKhungGio NVARCHAR(50),
    ThoiGianBatDau TIME,
    ThoiGianKetThuc TIME
);

CREATE TABLE TheXeThang (
    IDTheThang VARCHAR(12) PRIMARY KEY ,--TXT001_12T(Thẻ xe tháng 001,12)
    IDKhachHangNo VARCHAR(12) NOT NULL,
    IDXeNo VARCHAR(12) NOT NULL,
    TenTheXe NVARCHAR(100),
    NgayDangKy DATE DEFAULT GETDATE(),
    NgayHetHan DATE NOT NULL,
    TrangThai BIT DEFAULT 1,

    -- Ràng buộc đồng bộ: Nếu IDXe thay đổi hoặc Khách hàng bị xóa, thẻ sẽ tự cập nhật/xóa theo
    CONSTRAINT FK_TheXe_KHXe FOREIGN KEY (IDKhachHangNo, IDXeNo) 
        REFERENCES KhachHang_Xe(IDKhachHangNo, IDXeNo) 
        ON UPDATE CASCADE 
        ON DELETE CASCADE
);

CREATE TABLE Voucher (
    IDVoucher VARCHAR(15) PRIMARY KEY ,--VC00001_BD001(Voucher 00001,Bãi đỗ 001)
    IDBaiDoNo VARCHAR(8) CONSTRAINT FK_Voucher_BaiDo FOREIGN KEY REFERENCES BaiDo(IDBaiDo)
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
    IDDatCho VARCHAR(20) PRIMARY KEY ,--DC0001_05012026(Dặt chỗ 00001,05/01/2026)
    IDKhachHangNo VARCHAR(12) NOT NULL,
    IDXeNo VARCHAR(12) NOT NULL,
    IDChoDauNo VARCHAR(12) NOT NULL,
    IDNhanVienNo VARCHAR(10),
    TgianBatDau DATETIME,
    TgianKetThuc DATETIME,
    TrangThai NVARCHAR(50) CONSTRAINT CK_DatCho_TrangThai 
        CHECK (TrangThai IN (N'Đã đặt', N'Đã hủy', N'Đang chờ duyệt', N'Quá hạn', N'Hoàn thành')),

    -- Ràng buộc tham chiếu cặp Khách-Xe
    CONSTRAINT FK_DatCho_KHXe FOREIGN KEY (IDKhachHangNo, IDXeNo) 
        REFERENCES KhachHang_Xe(IDKhachHangNo, IDXeNo) 
        ON UPDATE CASCADE 
        ON DELETE CASCADE,

    CONSTRAINT FK_DatCho_NhanVien FOREIGN KEY (IDNhanVienNo) REFERENCES NhanVien(IDNhanVien) 
        ON UPDATE NO ACTION ON DELETE NO ACTION,
        
    CONSTRAINT FK_DatCho_ChoDau FOREIGN KEY (IDChoDauNo) REFERENCES ChoDauXe(IDChoDauXe) 
        ON UPDATE NO ACTION ON DELETE NO ACTION
);

CREATE TABLE HoaDon (
    IDHoaDon VARCHAR(20) PRIMARY KEY,--HD0001_05012026(Hoá đơn 0001,05/01/2026)
    ThanhTien DECIMAL(18,2),
    NgayTao DATETIME DEFAULT GETDATE(),
    LoaiHoaDon NVARCHAR(50),
    IDVoucher VARCHAR(15) CONSTRAINT FK_HoaDon_Voucher FOREIGN KEY REFERENCES Voucher(IDVoucher) 
            ON UPDATE NO ACTION 
            ON DELETE SET NULL 
);

CREATE TABLE PhieuGiuXe (
    IDPhieuGiuXe VARCHAR(15) PRIMARY KEY,--PX0001_A0001(Phiếu xe 0001,Vị trí A0001)
    IDKhachHangNo VARCHAR(12),
    IDXeNo VARCHAR(12) NOT NULL,
    IDChoDauNo VARCHAR(12) NOT NULL,
    IDNhanVienVao VARCHAR(10),
    IDNhanVienRa VARCHAR(10),
    IDHoaDonNo VARCHAR(20),
    TgianVao DATETIME DEFAULT GETDATE(),
    TgianRa DATETIME,
    TrangThai NVARCHAR(50) CONSTRAINT CK_PhieuGiuXe_TrangThai 
        CHECK (TrangThai IN (N'Đang gửi', N'Đã lấy', N'Quá hạn', N'Mất vé')),

    CONSTRAINT FK_PGX_KHXe FOREIGN KEY (IDKhachHangNo, IDXeNo) 
        REFERENCES KhachHang_Xe(IDKhachHangNo, IDXeNo) 
        ON UPDATE CASCADE 
        ON DELETE CASCADE,

    CONSTRAINT FK_PGX_ChoDau FOREIGN KEY (IDChoDauNo) REFERENCES ChoDauXe(IDChoDauXe) 
        ON UPDATE NO ACTION ON DELETE NO ACTION,
        
    CONSTRAINT FK_PGX_NVVao FOREIGN KEY (IDNhanVienVao) REFERENCES NhanVien(IDNhanVien) 
        ON UPDATE NO ACTION ON DELETE NO ACTION,
        
    CONSTRAINT FK_PGX_NVRa FOREIGN KEY (IDNhanVienRa) REFERENCES NhanVien(IDNhanVien) 
        ON UPDATE NO ACTION ON DELETE NO ACTION,
        
    CONSTRAINT FK_PGX_HoaDon FOREIGN KEY (IDHoaDonNo) REFERENCES HoaDon(IDHoaDon) 
        ON UPDATE NO ACTION ON DELETE NO ACTION
);

CREATE TABLE ChiTietHoaDon (
    IDChiTietHoaDon VARCHAR(30) PRIMARY KEY,--CTHD0001_HD0001(Chi tiết HD 0001,Hoá đon 0001)
    IDTheXeThangNo VARCHAR(12) CONSTRAINT FK_CTHD_TheXe FOREIGN KEY REFERENCES TheXeThang(IDTheThang) 
            ON UPDATE NO ACTION 
            ON DELETE NO ACTION,
    IDDatChoNo VARCHAR(20) CONSTRAINT FK_CTHD_DatCho FOREIGN KEY REFERENCES DatCho(IDDatCho) 
            ON UPDATE NO ACTION 
            ON DELETE NO ACTION,
    IDHoaDonNo VARCHAR(20) CONSTRAINT FK_CTHD_HoaDon FOREIGN KEY REFERENCES HoaDon(IDHoaDon) 
            ON UPDATE CASCADE 
            ON DELETE CASCADE,
    TongTien DECIMAL(18,2)
);

CREATE TABLE ThanhToan (
    IDThanhToan VARCHAR(20) PRIMARY KEY ,--TT00001_CK(Thanh toán 00001,Chuyển khoản)
    IDHoaDonNo VARCHAR(20) CONSTRAINT FK_ThanhToan_HoaDon FOREIGN KEY REFERENCES HoaDon(IDHoaDon) 
            ON UPDATE NO ACTION 
            ON DELETE NO ACTION,
    PhuongThuc NVARCHAR(50) CONSTRAINT CK_ThanhToan_PhuongThuc CHECK (PhuongThuc IN (N'Tiền mặt', N'Thẻ', N'QR Code', N'Chuyển khoản')),
    TrangThai BIT default 0,
    NgayThanhToan DATETIME DEFAULT GETDATE()
);

-- 7. BẢNG PHỤ TRỢ 
CREATE TABLE LichLamViec (
    IDLichLamViec VARCHAR(15) PRIMARY KEY,--LLV00001_NV001(Lịch làm việc 00001,Nhân viên 0001)
    IDNhanVienNo VARCHAR(10) CONSTRAINT FK_Lich_NhanVien FOREIGN KEY REFERENCES NhanVien(IDNhanVien) 
            ON UPDATE CASCADE 
            ON DELETE CASCADE,
    IDCaLamNo VARCHAR(8) CONSTRAINT FK_Lich_CaLam FOREIGN KEY REFERENCES CaLam(IDCaLam) 
            ON UPDATE CASCADE 
            ON DELETE CASCADE,
    IDBaiDoNo VARCHAR(8) CONSTRAINT FK_Lich_BaiDo FOREIGN KEY REFERENCES BaiDo(IDBaiDo) 
            ON UPDATE NO ACTION 
            ON DELETE NO ACTION,
    NgayBatDau DATE,
    NgayKetThuc DATE,
    TrangThai BIT DEFAULT 0,
    SoNgayDaLam INT
);

CREATE TABLE SuCo (
    IDSuCo VARCHAR(10) PRIMARY KEY ,--SC001_CA(Sự cố 001,Camera)
    IDNhanVienNo VARCHAR(10) CONSTRAINT FK_SuCo_NhanVien FOREIGN KEY REFERENCES NhanVien(IDNhanVien) 
            ON UPDATE NO ACTION 
            ON DELETE SET NULL, 
    IDThietBiNo VARCHAR(10) CONSTRAINT FK_SuCo_ThietBi FOREIGN KEY REFERENCES ThietBi(IDThietBi) 
            ON UPDATE NO ACTION 
            ON DELETE NO ACTION,
    MoTa NVARCHAR(MAX),
    MucDo NVARCHAR(50) CONSTRAINT CK_SuCo_MucDo CHECK (MucDo IN (N'Nhẹ', N'Trung bình', N'Nghiêm trọng')),
    TrangThaiXuLy NVARCHAR(50) CONSTRAINT CK_SuCo_TrangThaiXuLy CHECK (TrangThaiXuLy IN (N'Chưa xử lý', N'Đang xử lý', N'Đã xử lý'))
);

CREATE TABLE DanhGia (
    IDDanhGia VARCHAR(12) PRIMARY KEY ,--DG001_KH0001(Đánh giá 001,Khách hàng 0001)
    IDKhachHangNo VARCHAR(12) CONSTRAINT FK_DanhGia_KhachHang FOREIGN KEY REFERENCES KhachHang(IDKhachHang) 
            ON UPDATE CASCADE 
            ON DELETE CASCADE,
    IDHoaDonNo VARCHAR(20) CONSTRAINT FK_DanhGia_HoaDon FOREIGN KEY REFERENCES HoaDon(IDHoaDon) 
            ON UPDATE NO ACTION 
            ON DELETE NO ACTION, 
    NoiDung NVARCHAR(MAX),
    DiemDanhGia INT,
    NgayDanhGia DATETIME DEFAULT GETDATE()
);
GO

USE ParkingLot;
GO

-- VaiTro
INSERT INTO VaiTro VALUES
('VT01_NV', N'Nhân viên'),
('VT02_KH', N'Khách hàng'),
('VT03_CB', N'Chủ bãi');

-- LoaiXe
INSERT INTO LoaiXe VALUES
('LX01_XM', N'Xe máy'),
('LX02_O4', N'Ô tô 4 chỗ'),
('LX03_O7', N'Ô tô 7 chỗ');

-- CaLam
INSERT INTO CaLam VALUES
('CL01_S', N'Ca sáng', '06:00', '14:00', 1.0),
('CL02_C', N'Ca chiều', '14:00', '22:00', 1.1),
('CL03_D', N'Ca đêm', '22:00', '06:00', 1.3),
('CL04_HC', N'Ca hành chính', '08:00', '17:00', 1.0),
('CL05_TC', N'Ca tăng cường', '17:00', '22:00', 1.2);

INSERT INTO TaiKhoan VALUES
('TK00001_NV', 'VT01_NV', 'nvbao', '123456', NULL, 1),
('TK00002_KH', 'VT02_KH', 'khtinh', '123456', NULL, 1),
('TK00003_CB', 'VT03_CB', 'chubai1', '123456', NULL, 1);

-- Nhân viên
INSERT INTO NhanVien VALUES
('NV001_BV', 'TK00001_NV', N'Nguyễn Văn Bảo', '0912345678',
 'bao@gmail.com', N'Bảo vệ', 7000000);

-- Khách hàng
INSERT INTO KhachHang VALUES
('KH00001_VI', 'TK00002_KH', N'Lê Hoàng Quách Tỉnh', '0987654321',
 '012345678901', 'BLX12345', N'TP.HCM',
 N'VIP', '123456789', N'Vietcombank');

-- Chủ bãi
INSERT INTO ChuBaiXe VALUES
('CB001', 'TK00003_CB', N'Trần Minh Chủ', '0909123456',
 'chubai@gmail.com', '098765432109', N'TP.HCM');

-- Xe
INSERT INTO Xe VALUES
('59A-12345', 'LX02_O4', N'Toyota Vios', N'Toyota', N'Trắng', NULL);

-- Khách hàng - Xe
INSERT INTO KhachHang_Xe VALUES
('KH00001_VI', '59A-12345', N'Sở hữu');

-- Bãi đỗ
INSERT INTO BaiDo VALUES
('BD001', 'CB001', N'Bãi xe Trung tâm', N'Quận 1', 100, N'Hoạt động', NULL),
('BD002', 'CB001', N'Bãi xe Sân Bay', N'Tân Bình', 200, N'Hoạt động', NULL),
('BD003', 'CB001', N'Bãi xe Chung cư A', N'Quận 7', 120, N'Bảo trì', NULL);

-- Khu vực
INSERT INTO KhuVuc VALUES
('KV001_A', 'BD001', N'Khu A', 50, NULL),
('KV002_B', 'BD001', N'Khu B', 50, NULL),
('KV003_C', 'BD001', N'Khu C', 30, NULL),
('KV004_A', 'BD002', N'Khu A', 100, NULL),
('KV005_B', 'BD003', N'Khu B', 60, NULL);

-- Chỗ đậu
INSERT INTO ChoDauXe VALUES
('CD0001_A', 'KV001_A', N'A01', '2.5m x 5m', N'Trống');

INSERT INTO ThietBi VALUES
('TB001_CA', 'KV001_A', N'Camera A1', N'Camera',
 N'Hoạt động', '2024-01-01', 5000000),
 ('TB002_CB', 'KV001_A', N'Barrier tự động', N'Cổng chắn',
 N'Hoạt động', '2024-06-01', 12000000),

('TB003_CB', 'KV002_B', N'Barrier phụ', N'Cổng chắn',
 N'Bảo trì', '2023-12-15', 9000000),

('TB004_PM', 'KV004_A', N'Phần mềm nhận diện biển số', N'Phần mềm',
 N'Hoạt động', '2024-08-20', 25000000);

-- Bảng giá
INSERT INTO BangGia VALUES
('BG001_O4', 'BD001', 'LX02_O4', N'Giá ô tô 4 chỗ', 1),
('BG002_XM', 'BD001', 'LX01_XM', N'Giá xe máy', 1),
('BG003_O7', 'BD001', 'LX03_O7', N'Giá ô tô 7 chỗ', 1),

('BG004_O4', 'BD002', 'LX02_O4', N'Giá ô tô 4 chỗ - Sân bay', 1),
('BG005_XM', 'BD002', 'LX01_XM', N'Giá xe máy - Sân bay', 1);

-- Loại hình tính phí
INSERT INTO LoaiHinhTinhPhi VALUES
('LH001_GIO_O4', 'BG001_O4', N'Tính theo giờ', N'Giờ', 20000),
('LH002_GIO_XM', 'BG002_XM', N'Tính theo giờ', N'Giờ', 5000),
('LH003_NGAY_XM', 'BG002_XM', N'Tính theo ngày', N'Ngày', 30000),

('LH004_GIO_O7', 'BG003_O7', N'Tính theo giờ', N'Giờ', 30000),
('LH005_NGAY_O7', 'BG003_O7', N'Tính theo ngày', N'Ngày', 200000),

('LH006_GIO_O4', 'BG004_O4', N'Tính theo giờ', N'Giờ', 40000),
('LH007_NGAY_O4', 'BG004_O4', N'Tính theo ngày', N'Ngày', 300000),

('LH008_THG_XM', 'BG002_XM', N'Tính theo tháng', N'Tháng', 150000),
('LH009_THG_O4', 'BG001_O4', N'Tính theo tháng', N'Tháng', 1200000),
('LH010_THG_O7', 'BG003_O7', N'Tính theo tháng', N'Tháng', 1500000);

-- Khung giờ
INSERT INTO KhungGio VALUES
('KG01_HC', 'LH001_GIO_O4', N'Giờ hành chính', '06:00', '18:00'),
('KG02_GN', 'LH002_GIO_XM', N'Giờ ban ngày', '06:00', '18:00'),
('KG03_GD', 'LH002_GIO_XM', N'Giờ ban đêm', '18:00', '06:00'),

('KG04_GN', 'LH004_GIO_O7', N'Giờ ban ngày', '06:00', '18:00'),
('KG05_GD', 'LH004_GIO_O7', N'Giờ ban đêm', '18:00', '06:00'),

('KG06_HC', 'LH006_GIO_O4', N'Giờ cao điểm', '07:00', '19:00'),
('KG07_TC', 'LH006_GIO_O4', N'Giờ thấp điểm', '19:00', '07:00');

-- Thẻ xe tháng
INSERT INTO TheXeThang VALUES
('TXT001_12T', 'KH00001_VI', '59A-12345',
 N'Thẻ xe tháng 12T', GETDATE(), '2026-01-01', 1);

-- Voucher
INSERT INTO Voucher VALUES
('VC00001_BD001', 'BD001', N'Giảm 20K', 20000,
 '2026-12-31', 100, 1, 'VC20K'),
 ('VC00002_BD001', 'BD001', N'Giảm 10%', 10000, '2026-06-30', 200, 1, 'G10P'),
('VC00001_BD002', 'BD002', N'Giảm 50K sân bay', 50000, '2026-12-31', 100, 1, 'SB50K'),
('VC00001_BD003', 'BD003', N'Khuyến mãi bảo trì', 30000, '2025-12-31', 50, 0, 'KM30K');


-- Đặt chỗ
INSERT INTO DatCho VALUES
('DC0001_05012026', 'KH00001_VI', '59A-12345',
 'CD0001_A', 'NV001_BV',
 '2026-01-05 08:00', '2026-01-05 12:00',
 N'Hoàn thành');

-- Hóa đơn
INSERT INTO HoaDon VALUES
('HD0001_05012026', 80000, GETDATE(), N'Giữ xe', 'VC00001_BD001');

-- Phiếu giữ xe
INSERT INTO PhieuGiuXe VALUES
('PX0001_A0001', 'KH00001_VI', '59A-12345',
 'CD0001_A', 'NV001_BV', 'NV001_BV',
 'HD0001_05012026',
 GETDATE(), GETDATE(), N'Đã lấy');

-- Chi tiết hóa đơn
INSERT INTO ChiTietHoaDon VALUES
('CTHD0001_HD0001', 'TXT001_12T', 'DC0001_05012026',
 'HD0001_05012026', 80000);

-- Thanh toán
INSERT INTO ThanhToan VALUES
('TT00001_CK', 'HD0001_05012026',
 N'Chuyển khoản', 1, GETDATE());

-- Lịch làm việc
INSERT INTO LichLamViec VALUES
('LLV00001_001', 'NV001_BV', 'CL01_S',
 'BD001', '2026-01-01', '2026-01-31', 1, 20);

-- Sự cố
INSERT INTO SuCo VALUES
('SC001_CA', 'NV001_BV', 'TB001_CA',
 N'Camera mờ', N'Nhẹ', N'Đã xử lý');

-- Đánh giá
INSERT INTO DanhGia VALUES
('DG001_0001', 'KH00001_VI',
 'HD0001_05012026', N'Dịch vụ tốt', 5, GETDATE());


