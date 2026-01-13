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
    TrangThai NVARCHAR(50) CONSTRAINT CK_ChoDauXe_TrangThai CHECK (TrangThai IN (N'Trống', N'Đã đặt', N'Đang đỗ', N'Bảo trì', N'chờ xác nhận'))
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
        CHECK (TrangThai IN (N'Chờ thanh toán',N'Đã thanh toán',N'Đã đặt', N'Đã hủy', N'Đang chờ duyệt', N'Quá hạn', N'Hoàn thành')),

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
    IDChiTietHoaDon VARCHAR(50) PRIMARY KEY,--CTHD0001_HD0001(Chi tiết HD 0001,Hoá đon 0001)
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
    IDThanhToan VARCHAR(15) PRIMARY KEY ,--TT00001_CK(Thanh toán 00001,Chuyển khoản)
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
    NgayBatDau DATE not null,
    NgayKetThuc DATE not null,
    TrangThai BIT DEFAULT 0,
    SoNgayDaLam INT,
	CONSTRAINT CK_LichLamViec_Ngay
        CHECK (NgayKetThuc >= NgayBatDau)
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
('CD0001_A', 'KV001_A', N'A01', '2.5m x 5m', N'Trống'),
('CD0002_A', 'KV001_A', N'A02', '2.5m x 5m', N'Trống'),
('CD0003_A', 'KV001_A', N'A03', '2.5m x 5m', N'Trống'),
('CD0004_A', 'KV001_A', N'A04', '2.5m x 5m', N'Trống'),
('CD0005_A', 'KV001_A', N'A05', '2.5m x 5m', N'Trống'),
('CD0001_B', 'KV002_B', N'B01', '2.5m x 5m', N'Trống'),
('CD0002_B', 'KV002_B', N'B02', '2.5m x 5m', N'Trống'),
('CD0003_B', 'KV002_B', N'B03', '2.5m x 5m', N'Trống'),
('CD0004_B', 'KV002_B', N'B04', '2.5m x 5m', N'Trống'),
('CD0005_B', 'KV002_B', N'B05', '2.5m x 5m', N'Trống');


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
('VC00001_BD001', 'BD001', N'Giảm 20K', 0,
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






-- ====================Function========================
IF OBJECT_ID('f_TimKiemChoTrong') IS NOT NULL 
    DROP FUNCTION f_TimKiemChoTrong;
GO

CREATE FUNCTION f_TimKiemChoTrong
(
    @IDBaiDo   VARCHAR(8),
    @IDLoaiXe  VARCHAR(10),
    @ThoiDiem  DATETIME
)
RETURNS TABLE
AS
RETURN
(
    SELECT 
        bd.TenBai,
        kv.TenKhuVuc,
        cd.TenChoDau,
        cd.KichThuoc,
        cd.TrangThai,
		lx.TenLoaiXe,

        -- CỘT GIÁ
        lhtp.GiaTien AS GiaApDung

    FROM ChoDauXe cd
    JOIN KhuVuc kv 
        ON cd.IDKhuVucNo = kv.IDKhuVuc
    JOIN BaiDo bd 
        ON kv.IDBaiDoNo = bd.IDBaiDo

    -- Bảng giá
    JOIN BangGia bg 
        ON bg.IDBaiDoNo = bd.IDBaiDo
       AND bg.IDLoaiXeNo = @IDLoaiXe
       AND bg.HieuLuc = 1

    JOIN LoaiHinhTinhPhi lhtp 
        ON lhtp.IDBangGiaNo = bg.IDBangGia

    JOIN KhungGio kg 
        ON kg.IDLoaiHinhTinhPhiNo = lhtp.IDLoaiHinhTinhPhi

	join LoaiXe lx 
		on lx.IDLoaiXe = @IDLoaiXe

    WHERE cd.TrangThai = N'Trống'
      AND (@IDBaiDo IS NULL OR bd.IDBaiDo = @IDBaiDo)

      -- XÁC ĐỊNH KHUNG GIỜ THEO THỜI ĐIỂM
      AND (
            (kg.ThoiGianBatDau < kg.ThoiGianKetThuc
             AND CAST(@ThoiDiem AS TIME)
                 BETWEEN kg.ThoiGianBatDau AND kg.ThoiGianKetThuc)
         OR (kg.ThoiGianBatDau > kg.ThoiGianKetThuc
             AND (
                 CAST(@ThoiDiem AS TIME) >= kg.ThoiGianBatDau
                 OR CAST(@ThoiDiem AS TIME) <= kg.ThoiGianKetThuc
             ))
      )
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
    JOIN ThanhToan tt ON hd.IDHoaDon = tt.IDHoaDonNo
    WHERE MONTH(tt.NgayThanhToan) = @Thang 
      AND YEAR(tt.NgayThanhToan) = @Nam 
      AND tt.TrangThai = 1; 
    RETURN ISNULL(@TongTien, 0);
END;
GO


-- ====================Procedure========================


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
    LEFT JOIN KhachHang_Xe khx ON x.BienSoXe = khx.IDXeNo
    LEFT JOIN KhachHang kh ON khx.IDKhachHangNo = kh.IDKhachHang
    LEFT JOIN PhieuGiuXe pgx ON (x.BienSoXe = pgx.IDXeNo AND kh.IDKhachHang = pgx.IDKhachHangNo)
    LEFT JOIN ChoDauXe cd ON pgx.IDChoDauNo = cd.IDChoDauXe
    LEFT JOIN KhuVuc kv ON cd.IDKhuVucNo = kv.IDKhuVuc
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
        COUNT(DISTINCT pgx.IDPhieuGiuXe) AS SoLuotXeVao,
        SUM(hd.ThanhTien) AS DoanhThu,
        COUNT(hd.IDVoucher) AS SoVoucherSuDung
    FROM ThanhToan tt
    JOIN HoaDon hd ON tt.IDHoaDonNo = hd.IDHoaDon
    LEFT JOIN PhieuGiuXe pgx ON hd.IDHoaDon = pgx.IDHoaDonNo
    WHERE CAST(tt.NgayThanhToan AS DATE) BETWEEN @NgayBatDau AND @NgayKetThuc 
      AND tt.TrangThai = 1
    GROUP BY CAST(tt.NgayThanhToan AS DATE)
    ORDER BY Ngay DESC;
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
            -- 1. Generate ID for TaiKhoan
            DECLARE @SoTK INT, @IDTK VARCHAR(15);
            EXEC sp_SinhMa 'TaiKhoan', @SoTK OUTPUT;
            
            -- Suffix logic for TaiKhoan (KhachHang defers to _KH usually, but let's match sp_ThemTaiKhoan logic)
            -- In sp_ThemTaiKhoan: IF @IDVaiTroNo LIKE '%_NV' ...
            -- Here hardcoded 'VT02_KH', so suffix is '_KH'
            SET @IDTK = 'TK' + RIGHT('00000' + CAST(@SoTK AS VARCHAR), 5) + '_KH';

            INSERT INTO TaiKhoan (IDTaiKhoan, IDVaiTroNo, TenDangNhap, MatKhau) 
            VALUES (@IDTK, 'VT02_KH', @TenDangNhap, @MatKhau);
            
            -- 2. Generate ID for KhachHang
            DECLARE @SoKH INT, @IDKH VARCHAR(12);
            EXEC sp_SinhMa 'KhachHang', @SoKH OUTPUT;
            
            -- Default LoaiKH is 'Thường xuyên' -> Suffix '_TX'
            SET @IDKH = 'KH' + RIGHT('00000' + CAST(@SoKH AS VARCHAR), 5) + '_TX';

            INSERT INTO KhachHang (IDKhachHang, IDTaiKhoanNo, HoTen, SDT, CCCD, DiaChi, LoaiKH)
            VALUES (@IDKH, @IDTK, @HoTen, @SDT, @CCCD, @DiaChi, N'Thường xuyên');

            SELECT @IDTK AS IDTaiKhoan, @IDKH AS IDKhachHang;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION; 
        DECLARE @ErrMsg NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrMsg, 16, 1);
    END CATCH
END;
GO


-- Thêm Xe và Liên kết với Khách hàng
IF OBJECT_ID('sp_ThemXeKhachHang') IS NOT NULL 
    DROP PROCEDURE sp_ThemXeKhachHang;
GO

CREATE PROCEDURE sp_ThemXeKhachHang
    @IDKhachHang VARCHAR(12), 
    @BienSoXe    VARCHAR(20), 
    @IDLoaiXe    VARCHAR(10), 
    @TenXe       NVARCHAR(100), 
    @Hang        NVARCHAR(50), 
    @MauSac      NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    -- Thêm xe nếu chưa tồn tại
    IF NOT EXISTS (
        SELECT 1 
        FROM dbo.Xe 
        WHERE BienSoXe = @BienSoXe
    )
    BEGIN
        INSERT INTO dbo.Xe (BienSoXe, IDLoaiXeNo, TenXe, Hang, MauSac)
        VALUES (@BienSoXe, @IDLoaiXe, @TenXe, @Hang, @MauSac);
    END

    -- Gán xe cho khách hàng
    IF NOT EXISTS (
        SELECT 1 
        FROM dbo.KhachHang_Xe 
        WHERE IDKhachHangNo = @IDKhachHang 
          AND IDXeNo = @BienSoXe
    )
    BEGIN
        INSERT INTO dbo.KhachHang_Xe (IDKhachHangNo, IDXeNo, LoaiSoHuu)
        VALUES (@IDKhachHang, @BienSoXe, N'Chính chủ');
    END
END;
GO



-- Khách hàng đặt chỗ
IF OBJECT_ID('sp_KhachHangDatCho') IS NOT NULL DROP PROCEDURE sp_KhachHangDatCho;
GO
CREATE PROCEDURE sp_KhachHangDatCho
    @IDKhachHang VARCHAR(12),
    @BienSoXe VARCHAR(20),
    @IDChoDau VARCHAR(12),
    @TgianBatDau DATETIME,
    @TgianKetThuc DATETIME
AS
BEGIN
    SET NOCOUNT ON;

    -- 1. KIỂM TRA TÍNH HỢP LỆ CỦA THỜI GIAN
    IF @TgianBatDau >= @TgianKetThuc
    BEGIN
        RAISERROR(N'Lỗi: Thời gian kết thúc phải sau thời gian bắt đầu!', 16, 1);
        RETURN;
    END

    IF @TgianBatDau < GETDATE()
    BEGIN
        RAISERROR(N'Lỗi: Không thể đặt chỗ cho thời gian trong quá khứ!', 16, 1);
        RETURN;
    END

    -- 2. KIỂM TRA QUYỀN SỞ HỮU XE (Khách hàng - Xe)
    IF NOT EXISTS (SELECT 1 FROM KhachHang_Xe WHERE IDKhachHangNo = @IDKhachHang AND IDXeNo = @BienSoXe)
    BEGIN
        RAISERROR(N'Lỗi: Xe này chưa được đăng ký dưới tên khách hàng này!', 16, 1);
        RETURN;
    END

    -- 3. KIỂM TRA TRẠNG THÁI CẤU HÌNH CỦA CHỖ ĐỖ
    -- Nếu chỗ đang bảo trì hoặc tạm dừng thì không cho đặt
    IF EXISTS (SELECT 1 FROM ChoDauXe WHERE IDChoDauXe = @IDChoDau AND TrangThai IN (N'Bảo trì', N'Tạm dừng', N'Đóng cửa'))
    BEGIN
        RAISERROR(N'Lỗi: Vị trí đỗ xe này đang bảo trì hoặc tạm dừng hoạt động!', 16, 1);
        RETURN;
    END

    -- 4. KIỂM TRA TRÙNG LỊCH ĐẶT (Booking Overlap)
    IF EXISTS (
        SELECT 1 
        FROM DatCho 
        WHERE IDChoDauNo = @IDChoDau 
        AND TrangThai IN (N'Đã đặt', N'Đang chờ duyệt') -- Chỉ kiểm tra các lịch đang active
        AND (@TgianBatDau < TgianKetThuc AND @TgianKetThuc > TgianBatDau)
    )
    BEGIN
        RAISERROR(N'Lỗi: Khung giờ này đã có người khác đặt chỗ!', 16, 1);
        RETURN;
    END

    -- 5. KIỂM TRA XE ĐANG ĐỖ THỰC TẾ 
    IF EXISTS (
        SELECT 1 
        FROM PhieuGiuXe 
        WHERE IDChoDauNo = @IDChoDau 
        AND TgianRa IS NULL -- Xe chưa ra
        AND @TgianBatDau <= GETDATE() -- Khách muốn đặt ngay lúc này
    )
    BEGIN
        RAISERROR(N'Lỗi: Vị trí này hiện đang có xe đỗ, vui lòng chọn chỗ khác hoặc khung giờ khác!', 16, 1);
        RETURN;
    END

    -- 6. THỰC HIỆN ĐẶT CHỖ
    BEGIN TRY
        DECLARE @So INT, @IDDC VARCHAR(20);
        EXEC sp_SinhMa 'DatCho', @So OUTPUT;

        DECLARE @DateStr VARCHAR(10) = REPLACE(CONVERT(VARCHAR, GETDATE(), 103), '/', '');
        SET @IDDC = 'DC' + RIGHT('0000' + CAST(@So AS VARCHAR), 4) + '_' + @DateStr;

        INSERT INTO DatCho (IDDatCho, IDKhachHangNo, IDXeNo, IDChoDauNo, TgianBatDau, TgianKetThuc, TrangThai)
        VALUES (@IDDC, @IDKhachHang, @BienSoXe, @IDChoDau, @TgianBatDau, @TgianKetThuc, N'Đang chờ duyệt');
        
        PRINT N'Đặt chỗ thành công cho xe ' + @BienSoXe + N' tại vị trí ID ' + @IDChoDau;
    END TRY
    BEGIN CATCH
        DECLARE @ErrMsg NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrMsg, 16, 1);
    END CATCH
END;
GO

--khách hàng hủy đặt chỗ
IF OBJECT_ID('sp_KhachHangHuyDatCho') IS NOT NULL DROP PROCEDURE sp_KhachHangHuyDatCho;
GO
CREATE PROCEDURE sp_KhachHangHuyDatCho
    @IDDatCho VARCHAR(20),
    @IDKhachHang VARCHAR(12)
AS
BEGIN
    SET NOCOUNT ON;

    -- Chỉ cho hủy khi là chủ đơn và chưa bắt đầu gửi xe
    IF NOT EXISTS (
        SELECT 1
        FROM DatCho
        WHERE IDDatCho = @IDDatCho
          AND IDKhachHangNo = @IDKhachHang
          AND TrangThai IN (N'Đã đặt',N'Đang chờ duyệt')
          AND TgianBatDau > GETDATE()
    )
    BEGIN
        RAISERROR(
            N'Không thể hủy đặt chỗ (không tồn tại, đã xử lý hoặc quá giờ).',
            16, 1
        );
        RETURN;
    END

    UPDATE DatCho
    SET TrangThai = N'Đã hủy'
    WHERE IDDatCho = @IDDatCho;

    PRINT N'Khách hàng đã hủy đặt chỗ thành công.';
END;
GO


-- Nhân viên duyệt
IF OBJECT_ID('sp_NhanVienDuyetDatCho') IS NOT NULL DROP PROCEDURE sp_NhanVienDuyetDatCho;
GO
CREATE PROCEDURE sp_NhanVienDuyetDatCho
    @IDDatCho VARCHAR(20),
    @IDNhanVien VARCHAR(10),
    @TrangThaiMoi NVARCHAR(50) -- N'Đã đặt' (Duyệt) hoặc N'Đã hủy' (Từ chối)
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @IDChoDau VARCHAR(12);
    DECLARE @TrangThaiHienTai NVARCHAR(50);

    -- Lấy thông tin chỗ đậu từ đơn đặt hàng
    SELECT @IDChoDau = IDChoDauNo, @TrangThaiHienTai = TrangThai
    FROM DatCho 
    WHERE IDDatCho = @IDDatCho;

    -- 1. Kiểm tra đơn này có tồn tại không
    IF @IDChoDau IS NULL
    BEGIN
        RAISERROR(N'Lỗi: Đơn đặt chỗ không tồn tại.', 16, 1);
        RETURN;
    END

    -- 2. Kiểm tra trạng thái đơn (Chỉ được duyệt đơn đang chờ)
    IF @TrangThaiHienTai <> N'Đang chờ duyệt'
    BEGIN
        RAISERROR(N'Lỗi: Đơn này đã được xử lý hoặc không ở trạng thái chờ duyệt.', 16, 1);
        RETURN;
    END

    BEGIN TRY
        BEGIN TRANSACTION;

            -- TRƯỜNG HỢP 1: DUYỆT ĐƠN (Chấp nhận)
            IF @TrangThaiMoi = N'Đã đặt'
            BEGIN
                -- Kiểm tra lại xem chỗ đó có còn TRỐNG không?
                -- (Tránh trường hợp trong lúc chờ duyệt, xe khác đã vào đỗ hoặc bảo trì)
                IF EXISTS (SELECT 1 FROM ChoDauXe WHERE IDChoDauXe = @IDChoDau AND TrangThai <> N'Trống')
                BEGIN
                    RAISERROR(N'Lỗi: Không thể duyệt. Chỗ đậu xe này hiện không còn trống (Đang đỗ/Bảo trì).', 16, 1);
                    ROLLBACK TRANSACTION;
                    RETURN;
                END
                -- Cập nhật trạng thái Chỗ đậu -> "Đã đặt"
                UPDATE ChoDauXe SET TrangThai = N'Đã đặt' WHERE IDChoDauXe = @IDChoDau;
            END

            -- TRƯỜNG HỢP 2: TỪ CHỐI/HỦY ĐƠN
            ELSE IF @TrangThaiMoi = N'Đã hủy'
            BEGIN
                UPDATE ChoDauXe SET TrangThai = N'Trống' WHERE IDChoDauXe = @IDChoDau AND TrangThai = N'Đã đặt';
            END

            -- 3. Cập nhật trạng thái Đơn đặt chỗ
            UPDATE DatCho
            SET TrangThai = @TrangThaiMoi,
                IDNhanVienNo = @IDNhanVien
            WHERE IDDatCho = @IDDatCho;

            PRINT N'Cập nhật trạng thái đặt chỗ thành công: ' + @TrangThaiMoi;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        DECLARE @ErrMsg NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrMsg, 16, 1);
    END CATCH
END;
GO


IF OBJECT_ID('sp_XemXeCuaKhachHang') IS NOT NULL DROP PROCEDURE sp_XemXeCuaKhachHang;
GO
CREATE PROCEDURE sp_XemXeCuaKhachHang @IDKhachHang VARCHAR(12)
AS
BEGIN
    SELECT kh.HoTen, x.BienSoXe, lx.TenLoaiXe, x.TenXe, x.MauSac
    FROM KhachHang kh
    JOIN KhachHang_Xe khx ON kh.IDKhachHang = khx.IDKhachHangNo
    JOIN Xe x ON khx.IDXeNo = x.BienSoXe
    JOIN LoaiXe lx ON x.IDLoaiXeNo = lx.IDLoaiXe
    WHERE kh.IDKhachHang = @IDKhachHang;
END;
GO

-- Thống kê danh sách đặt chỗ đang chờ duyệt (Trạng thái 'Đang chờ duyệt')
IF OBJECT_ID('sp_DanhSachChoDuyet') IS NOT NULL DROP PROCEDURE sp_DanhSachChoDuyet;
GO
CREATE PROCEDURE sp_DanhSachChoDuyet
AS
BEGIN
    SELECT dc.IDDatCho AS IDDatCho, kh.HoTen, kh.SDT, cd.TenChoDau, dc.TgianBatDau, dc.TgianKetThuc
    FROM DatCho dc
    JOIN KhachHang kh ON dc.IDKhachHangNo = kh.IDKhachHang
    JOIN ChoDauXe cd ON dc.IDChoDauNo = cd.IDChoDauXe
    WHERE dc.TrangThai = N'Đang chờ duyệt'
    ORDER BY dc.TgianBatDau ASC;
END;
GO




-- Thủ tục Xe vào bãi
IF OBJECT_ID('sp_XeVaoBai') IS NOT NULL DROP PROCEDURE sp_XeVaoBai;
GO
CREATE PROCEDURE sp_XeVaoBai
    @IDKhachHang VARCHAR(12), @BienSoXe VARCHAR(20), @IDChoDau VARCHAR(12), @IDNhanVien VARCHAR(10)
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Generate ID for PhieuGiuXe (Format: PXxxxx_Axxxx)
    -- Must extract suffix from ChoDau
    DECLARE @So INT, @IDPX VARCHAR(15);
    EXEC sp_SinhMa 'PhieuGiuXe', @So OUTPUT;

    DECLARE @ChoSuffix VARCHAR(10) = '';
    DECLARE @ChoNum VARCHAR(10) = '';
    
    IF CHARINDEX('_', @IDChoDau) > 0
    BEGIN
        SET @ChoSuffix = SUBSTRING(@IDChoDau, CHARINDEX('_', @IDChoDau)+1, LEN(@IDChoDau));
        SET @ChoNum = SUBSTRING(@IDChoDau, 3, CHARINDEX('_', @IDChoDau)-3);
    END

    SET @IDPX = 'PX' + RIGHT('0000' + CAST(@So AS VARCHAR), 4) + '_' + @ChoSuffix + @ChoNum;
    
    -- Insert
    INSERT INTO PhieuGiuXe (IDPhieuGiuXe, IDKhachHangNo, IDXeNo, IDChoDauNo, IDNhanVienVao, TgianVao, TrangThai)
    VALUES (@IDPX, @IDKhachHang, @BienSoXe, @IDChoDau, @IDNhanVien, GETDATE(), N'Đang gửi');

     PRINT N'Xe đã vào bãi thành công. Mã phiếu: ' + @IDPX;
END;

GO
-- Thủ tục Xe ra bãi
IF OBJECT_ID('sp_XeRaBai') IS NOT NULL DROP PROCEDURE sp_XeRaBai;
GO
CREATE PROCEDURE sp_XeRaBai
    @IDPhieuGiuXe VARCHAR(15),
    @IDNhanVienRa VARCHAR(10)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
            
            -- 1. Kiểm tra xem phiếu có tồn tại và xe đã ra chưa
            IF NOT EXISTS (SELECT 1 FROM PhieuGiuXe WHERE IDPhieuGiuXe = @IDPhieuGiuXe AND TgianRa IS NULL)
            BEGIN
                RAISERROR(N'Lỗi: Phiếu giữ xe không tồn tại hoặc xe đã ra bãi trước đó.', 16, 1);
                ROLLBACK TRANSACTION;
                RETURN;
            END

            -- 2. Cập nhật thời gian ra, ID nhân viên xử lý và trạng thái
            -- Trigger trg_PhieuGiuXe_TinhTien sẽ tự động chạy
            
            UPDATE PhieuGiuXe 
            SET TgianRa = GETDATE(),
                IDNhanVienRa = @IDNhanVienRa,
                TrangThai = N'Đã lấy'
            WHERE IDPhieuGiuXe = @IDPhieuGiuXe;
            
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
-- Thống kê Doanh thu theo ngày
IF OBJECT_ID('sp_ThongKeDoanhThuTheoNgay') IS NOT NULL DROP PROCEDURE sp_ThongKeDoanhThuTheoNgay;
GO
CREATE PROCEDURE sp_ThongKeDoanhThuTheoNgay
    @Ngay DATE
AS
BEGIN
    SELECT 
        COUNT(IDHoaDon) AS SoLuotXe,
        SUM(ThanhTien) AS TongDoanhThu,
        AVG(ThanhTien) AS TrungBinhMoiLuot
    FROM HoaDon
    WHERE CAST(NgayTao AS DATE) = @Ngay;
END;
GO

--Xem giá thẻ tháng
IF OBJECT_ID('fn_LayGiaTheThang') IS NOT NULL DROP FUNCTION fn_LayGiaTheThang;
GO
CREATE FUNCTION fn_LayGiaTheThang (@BienSo VARCHAR(20), @IDBaiDo VARCHAR(8))
RETURNS DECIMAL(18,2)
AS
BEGIN
    DECLARE @Gia DECIMAL(18,2);
    SELECT TOP 1 @Gia = lhtp.GiaTien
    FROM BangGia bg
    JOIN LoaiHinhTinhPhi lhtp ON bg.IDBangGia = lhtp.IDBangGiaNo
    JOIN Xe x ON bg.IDLoaiXeNo = x.IDLoaiXeNo
    WHERE x.BienSoXe = @BienSo AND bg.IDBaiDoNo = @IDBaiDo AND lhtp.DonViThoiGian = N'Tháng';
    RETURN ISNULL(@Gia, 0);
END;
GO
--đăng ký thẻ xe tháng
IF OBJECT_ID('sp_DangKyTheXeThang', 'P') IS NOT NULL
    DROP PROCEDURE sp_DangKyTheXeThang;
GO

CREATE PROCEDURE sp_DangKyTheXeThang
    @IDKhachHang VARCHAR(12),
    @IDXe VARCHAR(20),
    @IDBaiDo VARCHAR(8),
    @TenTheXe NVARCHAR(255),
    @SoThang INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @GiaThang DECIMAL(18,2) = dbo.fn_LayGiaTheThang(@IDXe, @IDBaiDo);
    IF @GiaThang = 0
    BEGIN
        RAISERROR(N'Lỗi: Bãi đỗ này chưa cấu hình giá vé tháng!', 16, 1);
        RETURN;
    END

    DECLARE @NgayDangKy DATETIME = GETDATE();
    DECLARE @NgayHetHan DATETIME = DATEADD(MONTH, @SoThang, @NgayDangKy);
    DECLARE @TongTien DECIMAL(18,2) = @GiaThang * @SoThang;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- 1) Sinh ID cho TheXeThang
        DECLARE @SoThe INT;
        EXEC sp_SinhMa 'TheXeThang', @SoThe OUTPUT;
        DECLARE @IDThe VARCHAR(20) = 'TXT' + RIGHT('000' + CAST(@SoThe AS VARCHAR), 3) + '_' + CAST(@SoThang AS VARCHAR) + 'T';

        INSERT INTO TheXeThang (
            IDTheThang, IDKhachHangNo, IDXeNo, TenTheXe, NgayDangKy, NgayHetHan, TrangThai
        ) VALUES (
            @IDThe, @IDKhachHang, @IDXe, @TenTheXe, @NgayDangKy, @NgayHetHan, 1
        );

        -- 2) Sinh ID cho HoaDon
        DECLARE @SoHD INT;
        EXEC sp_SinhMa 'HoaDon', @SoHD OUTPUT;
        DECLARE @DateStr VARCHAR(10) = REPLACE(CONVERT(VARCHAR, GETDATE(), 103), '/', '');
        DECLARE @IDHD VARCHAR(20) = 'HD' + RIGHT('0000' + CAST(@SoHD AS VARCHAR), 4) + '_' + @DateStr;

        INSERT INTO HoaDon (IDHoaDon, ThanhTien, NgayTao, LoaiHoaDon)
        VALUES (@IDHD, @TongTien, GETDATE(), N'Đăng ký thẻ xe tháng');

        -- 3) Sinh ID ChiTietHoaDon
        DECLARE @SoCT INT;
        EXEC sp_SinhMa 'ChiTietHoaDon', @SoCT OUTPUT;
        DECLARE @IDCT VARCHAR(30) = 'CTHD' + RIGHT('0000' + CAST(@SoCT AS VARCHAR), 4) + '_' + LEFT(@IDHD, CHARINDEX('_', @IDHD + '_') - 1);

        INSERT INTO ChiTietHoaDon (IDChiTietHoaDon, IDHoaDonNo, IDTheXeThangNo, TongTien)
        VALUES (@IDCT, @IDHD, @IDThe, @TongTien);

        -- 4) Sinh ID ThanhToan
        DECLARE @SoTT INT;
        EXEC sp_SinhMa 'ThanhToan', @SoTT OUTPUT;
        DECLARE @IDTT VARCHAR(20) = 'TT' + RIGHT('00000' + CAST(@SoTT AS VARCHAR), 5) + '_TM';

        INSERT INTO ThanhToan (IDThanhToan, IDHoaDonNo, PhuongThuc, TrangThai, NgayThanhToan)
        VALUES (@IDTT, @IDHD, N'Tiền mặt', 1, GETDATE());

        COMMIT TRANSACTION;

        -- Trả kết quả dễ nhìn
        SELECT
            @IDThe   AS IDTheThang,
            @IDHD    AS IDHoaDon,
            @IDCT    AS IDChiTietHoaDon,
            @IDTT    AS IDThanhToan,
            @TongTien AS TongTien,
            @NgayHetHan AS NgayHetHan,
            N'Đăng ký thẻ thành công' AS GhiChu;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        DECLARE @Err NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@Err, 16, 1);
    END CATCH
END;
GO
--gia hạn thẻ xe tháng
IF OBJECT_ID('sp_GiaHanTheXeThang', 'P') IS NOT NULL
    DROP PROCEDURE sp_GiaHanTheXeThang;
GO

CREATE PROCEDURE sp_GiaHanTheXeThang
    @IDTheThang VARCHAR(20),
    @SoThang INT,
    @IDBaiDo VARCHAR(8)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @IDXe VARCHAR(20) = (SELECT TOP 1 IDXeNo FROM TheXeThang WHERE IDTheThang = @IDTheThang);
    IF @IDXe IS NULL
    BEGIN
        RAISERROR(N'Không tìm thấy thẻ: %s', 16, 1, @IDTheThang);
        RETURN;
    END

    DECLARE @GiaThang DECIMAL(18,2) = dbo.fn_LayGiaTheThang(@IDXe, @IDBaiDo);
    IF @GiaThang = 0
    BEGIN
        RAISERROR(N'Lỗi: Bãi đỗ này chưa cấu hình giá vé tháng!', 16, 1);
        RETURN;
    END

    DECLARE @TongTien DECIMAL(18,2) = @GiaThang * @SoThang;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- 1) Cập nhật ngày hết hạn
        UPDATE TheXeThang
        SET NgayHetHan = DATEADD(MONTH, @SoThang, NgayHetHan),
            TrangThai = 1
        WHERE IDTheThang = @IDTheThang;

        -- 2) Sinh ID HoaDon
        DECLARE @SoHD INT;
        EXEC sp_SinhMa 'HoaDon', @SoHD OUTPUT;
        DECLARE @DateStr VARCHAR(10) = REPLACE(CONVERT(VARCHAR, GETDATE(), 103), '/', '');
        DECLARE @IDHD VARCHAR(20) = 'HD' + RIGHT('0000' + CAST(@SoHD AS VARCHAR), 4) + '_' + @DateStr;

        INSERT INTO HoaDon (IDHoaDon, ThanhTien, NgayTao, LoaiHoaDon)
        VALUES (@IDHD, @TongTien, GETDATE(), N'Gia hạn thẻ tháng');

        -- 3) Sinh ID ChiTietHoaDon
        DECLARE @SoCT INT;
        EXEC sp_SinhMa 'ChiTietHoaDon', @SoCT OUTPUT;
        DECLARE @IDCT VARCHAR(30) = 'CTHD' + RIGHT('0000' + CAST(@SoCT AS VARCHAR), 4);

        INSERT INTO ChiTietHoaDon (IDChiTietHoaDon, IDHoaDonNo, IDTheXeThangNo, TongTien)
        VALUES (@IDCT, @IDHD, @IDTheThang, @TongTien);

        -- 4) Sinh ID ThanhToan
        DECLARE @SoTT INT;
        EXEC sp_SinhMa 'ThanhToan', @SoTT OUTPUT;
        DECLARE @IDTT VARCHAR(20) = 'TT' + RIGHT('00000' + CAST(@SoTT AS VARCHAR), 5) + '_CK';

        INSERT INTO ThanhToan (IDThanhToan, IDHoaDonNo, PhuongThuc, TrangThai, NgayThanhToan)
        VALUES (@IDTT, @IDHD, N'Chuyển khoản', 1, GETDATE());

        COMMIT TRANSACTION;

        -- Trả kết quả
        SELECT
            @IDHD AS IDHoaDon,
            @IDCT AS IDChiTietHoaDon,
            @IDTT AS IDThanhToan,
            @TongTien AS SoTienGiaHan,
            (SELECT NgayHetHan FROM TheXeThang WHERE IDTheThang = @IDTheThang) AS HanMoi,
            N'Gia hạn thành công' AS GhiChu;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

--Hủy thẻ xe tháng
IF OBJECT_ID('sp_HuyTheXeThang') IS NOT NULL DROP PROCEDURE sp_HuyTheXeThang;
GO
CREATE PROCEDURE sp_HuyTheXeThang
    @IDTheThang VARCHAR(12)
AS
BEGIN
    UPDATE TheXeThang SET TrangThai = 0 WHERE IDTheThang = @IDTheThang;
    PRINT N'Đã hủy trạng thái hoạt động của thẻ ' + @IDTheThang;
END;
GO
-------------------Tìm kiếm VÀ Thống kê tổng hợp theo Khách hàng--------------------
IF OBJECT_ID('sp_ThongKeChiTietKhachHang') IS NOT NULL DROP PROCEDURE sp_ThongKeChiTietKhachHang;
GO
CREATE PROCEDURE sp_ThongKeChiTietKhachHang
    @TuKhoa NVARCHAR(100) -- Có thể nhập Tên hoặc ID Khách hàng
AS
BEGIN
    SET NOCOUNT ON;

    -- Lấy ID khách hàng chính xác từ từ khóa
    DECLARE @TargetID VARCHAR(12);
    SELECT TOP 1 @TargetID = IDKhachHang FROM KhachHang 
    WHERE HoTen LIKE N'%' + @TuKhoa + '%' OR IDKhachHang = @TuKhoa;

    IF @TargetID IS NULL
    BEGIN
        PRINT N'Không tìm thấy khách hàng: ' + @TuKhoa;
        RETURN;
    END

    -- BẢNG 1: TỔNG QUAN TÀI KHOẢN
    SELECT 
        kh.IDKhachHang,
        kh.HoTen,
        kh.LoaiKH,
        (SELECT COUNT(*) FROM KhachHang_Xe WHERE IDKhachHangNo = kh.IDKhachHang) AS SoLuongXeDangKy,
        COUNT(pgx.IDPhieuGiuXe) AS TongSoLuotGui,
        SUM(ISNULL(hd.ThanhTien, 0)) AS TongTienDaChiTra
    FROM KhachHang kh
    LEFT JOIN PhieuGiuXe pgx ON kh.IDKhachHang = pgx.IDKhachHangNo
    LEFT JOIN HoaDon hd ON pgx.IDHoaDonNo = hd.IDHoaDon
    WHERE kh.IDKhachHang = @TargetID
    GROUP BY kh.IDKhachHang, kh.HoTen, kh.LoaiKH;

    -- BẢNG 2: LỊCH SỬ GỬI XE CHI TIẾT VÀ PHƯƠNG THỨC THANH TOÁN
    SELECT 
        pgx.IDPhieuGiuXe AS MaPhieu,
        pgx.IDXeNo AS BienSo,
        x.TenXe,
        pgx.TgianVao,
        pgx.TgianRa,
        DATEDIFF(MINUTE, pgx.TgianVao, pgx.TgianRa) AS SoPhutGui,
        hd.ThanhTien,
        tt.PhuongThuc AS PhuongThucThanhToan,
        tt.NgayThanhToan,
        CASE WHEN tt.TrangThai = 1 THEN N'Thành công' ELSE N'Chưa thanh toán' END AS TìnhTrạng
    FROM PhieuGiuXe pgx
    JOIN Xe x ON pgx.IDXeNo = x.BienSoXe
    JOIN HoaDon hd ON pgx.IDHoaDonNo = hd.IDHoaDon
    JOIN ThanhToan tt ON hd.IDHoaDon = tt.IDHoaDonNo
    WHERE pgx.IDKhachHangNo = @TargetID
    ORDER BY pgx.TgianVao DESC;
END;
GO

---------Thống kê chi tiết theo Biển số xe-----------------------
IF OBJECT_ID('sp_TraCuuLichSuXe') IS NOT NULL DROP PROCEDURE sp_TraCuuLichSuXe;
GO
CREATE PROCEDURE sp_TraCuuLichSuXe
    @BienSo VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        pgx.IDXeNo AS BienSo,
        kh.HoTen AS NguoiGui,
        bd.TenBai AS TaiBaiDo,
        cd.TenChoDau AS ViTri,
        pgx.TgianVao,
        pgx.TgianRa,
        hd.ThanhTien,
        tt.PhuongThuc
    FROM PhieuGiuXe pgx
    JOIN KhachHang kh ON pgx.IDKhachHangNo = kh.IDKhachHang
    JOIN ChoDauXe cd ON pgx.IDChoDauNo = cd.IDChoDauXe
    JOIN KhuVuc kv ON cd.IDKhuVucNo = kv.IDKhuVuc
    JOIN BaiDo bd ON kv.IDBaiDoNo = bd.IDBaiDo
    JOIN HoaDon hd ON pgx.IDHoaDonNo = hd.IDHoaDon
    JOIN ThanhToan tt ON hd.IDHoaDon = tt.IDHoaDonNo
    WHERE pgx.IDXeNo = @BienSo
    ORDER BY pgx.TgianVao DESC;
END;
GO

-----------------------PHANA LỊCH LÀM VIỆC NHÂN VIÊN----------------------------
IF OBJECT_ID('sp_PhanLichLamViec') IS NOT NULL DROP PROCEDURE sp_PhanLichLamViec;
GO
CREATE PROCEDURE sp_PhanLichLamViec
    @IDNhanVien VARCHAR(10),
    @IDCaLam VARCHAR(8),
    @IDBaiDo VARCHAR(8),
    @NgayBatDau DATE,
    @NgayKetThuc DATE
AS
BEGIN
    SET NOCOUNT ON;

    -- 1. Kiểm tra nhân viên có tồn tại không
    IF NOT EXISTS (SELECT 1 FROM NhanVien WHERE IDNhanVien = @IDNhanVien)
    BEGIN
        RAISERROR(N'Lỗi: Nhân viên không tồn tại trong hệ thống!', 16, 1);
        RETURN;
    END

    -- 2. Kiểm tra trùng lịch (Nếu nhân viên đã có lịch ca đó tại ngày đó)
    IF EXISTS (
        SELECT 1 FROM LichLamViec 
        WHERE IDNhanVienNo = @IDNhanVien 
        AND IDCaLamNo = @IDCaLam
        AND (@NgayBatDau <= NgayKetThuc AND @NgayKetThuc >= NgayBatDau)
    )
    BEGIN
        RAISERROR(N'Lỗi: Nhân viên đã có lịch làm ca này trong khoảng thời gian trên!', 16, 1);
        RETURN;
    END

    -- 3. Thực hiện thêm lịch làm việc
	exec sp_ThemLichLamViec @IDNhanVien, @IDCaLam, @IDBaiDo, @NgayBatDau, @NgayKetThuc;


    PRINT N'Đã phân lịch thành công cho nhân viên ' + @IDNhanVien;
END;
GO

--------------------------XEM LỊCH LÀM VIỆC-------------------------------
IF OBJECT_ID('sp_XemLichTrucChiTiet') IS NOT NULL DROP PROCEDURE sp_XemLichTrucChiTiet;
GO
CREATE PROCEDURE sp_XemLichTrucChiTiet
    @NgayKiemTra DATE = NULL, -- Nếu NULL sẽ lấy ngày hiện tại
    @IDBaiDo VARCHAR(8) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF @NgayKiemTra IS NULL SET @NgayKiemTra = CAST(GETDATE() AS DATE);

    SELECT 
        bd.TenBai AS TenBaiDo,
        cl.TenCa,
        cl.TgianBatDau,
        cl.TgianKetThuc,
        nv.TenNhanVien,
        nv.ChucVu,
        nv.SDT,
        llv.NgayBatDau,
        llv.NgayKetThuc
    FROM LichLamViec llv
    JOIN NhanVien nv ON llv.IDNhanVienNo = nv.IDNhanVien
    JOIN CaLam cl ON llv.IDCaLamNo = cl.IDCaLam
    JOIN BaiDo bd ON llv.IDBaiDoNo = bd.IDBaiDo
    WHERE @NgayKiemTra BETWEEN llv.NgayBatDau AND llv.NgayKetThuc
      AND (@IDBaiDo IS NULL OR llv.IDBaiDoNo = @IDBaiDo)
    ORDER BY bd.TenBai, cl.TgianBatDau;
END;
GO


-- ====================Trigger========================

-- 5. TRIGGER: Cập nhật chỗ khi Đặt vé
IF OBJECT_ID('trg_DatCho_CapNhatTrangThai') IS NOT NULL DROP TRIGGER trg_DatCho_CapNhatTrangThai;
GO

CREATE TRIGGER trg_DatCho_CapNhatTrangThai
ON DatCho AFTER INSERT 
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE c
    SET c.TrangThai = N'Đã đặt'
    FROM ChoDauXe c
    JOIN inserted i ON c.IDChoDauXe = i.IDChoDauNo
    WHERE i.TrangThai = N'Đã đặt';
END;
GO

-- 6. TRIGGER: Giải phóng chỗ khi Hủy đặt
IF OBJECT_ID('trg_DatCho_GiaiPhongCho') IS NOT NULL DROP TRIGGER trg_DatCho_GiaiPhongCho;
GO
CREATE TRIGGER trg_DatCho_GiaiPhongCho
ON DatCho AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;

    UPDATE c
    SET c.TrangThai = N'Trống'
    FROM ChoDauXe c
    JOIN inserted i ON c.IDChoDauXe = i.IDChoDauNo
    WHERE i.TrangThai IN (N'Đã hủy', N'Hoàn thành', N'Quá hạn');
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
    DECLARE @AffectedIDs TABLE (IDHoaDon VARCHAR(20));
    INSERT INTO @AffectedIDs SELECT IDHoaDonNo FROM Inserted
    UNION SELECT IDHoaDonNo FROM Deleted;

    -- Tính lại tổng tiền
    UPDATE HoaDon
    SET ThanhTien = (
        SELECT ISNULL(SUM(TongTien), 0)
        FROM ChiTietHoaDon
        WHERE ChiTietHoaDon.IDHoaDonNo = HoaDon.IDHoaDon
    )
    WHERE IDHoaDon IN (SELECT IDHoaDon FROM @AffectedIDs);
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
        JOIN Inserted i ON d.IDChoDauNo = i.IDChoDauNo
        WHERE d.IDDatCho <> i.IDDatCho -- Không so sánh với chính nó
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
            FROM Voucher v JOIN inserted i ON v.IDVoucher = i.IDVoucher
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
        FROM Voucher v JOIN inserted i ON v.IDVoucher = i.IDVoucher;
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
        JOIN inserted i ON t.IDTheThang = i.IDTheThang
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
        JOIN inserted i ON c.IDChoDauXe = i.IDChoDauNo;
    END

    -- TRƯỜNG HỢP 2: XE RA (UPDATE TgianRa) -> Trống
    IF UPDATE(TgianRa)
    BEGIN
        UPDATE ChoDauXe
        SET TrangThai = N'Trống'
        FROM ChoDauXe c
        JOIN inserted i ON c.IDChoDauXe = i.IDChoDauNo
        WHERE i.TgianRa IS NOT NULL;
    END
    
    -- TRƯỜNG HỢP 3: ĐỔI CHỖ (UPDATE IDChoDau) -> Cập nhật cả chỗ cũ và mới
    IF UPDATE(IDChoDauNo)
    BEGIN
        -- Chỗ cũ thành Trống
        UPDATE ChoDauXe SET TrangThai = N'Trống'
        FROM ChoDauXe c JOIN deleted d ON c.IDChoDauXe = d.IDChoDauNo;

        -- Chỗ mới thành Đang đỗ
        UPDATE ChoDauXe SET TrangThai = N'Đang đỗ'
        FROM ChoDauXe c JOIN inserted i ON c.IDChoDauXe = i.IDChoDauNo;
    END
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
        DECLARE @IDPhieu VARCHAR(15), @IDKH VARCHAR(12), @BienSo VARCHAR(20), 
                @Vao DATETIME, @Ra DATETIME, @IDLoaiXe VARCHAR(10), @IDBaiDo VARCHAR(8);
        DECLARE @SoGio INT, @DonGia DECIMAL(18,2), @TongTien DECIMAL(18,2);

        SELECT 
            @IDPhieu = i.IDPhieuGiuXe, 
            @IDKH = i.IDKhachHangNo, 
            @BienSo = i.IDXeNo, 
            @Vao = i.TgianVao, 
            @Ra = i.TgianRa, 
            @IDLoaiXe = x.IDLoaiXeNo,
            @IDBaiDo = kv.IDBaiDoNo
        FROM inserted i
        LEFT JOIN Xe x ON i.IDXeNo = x.BienSoXe
        JOIN ChoDauXe cd ON i.IDChoDauNo = cd.IDChoDauXe
        JOIN KhuVuc kv ON cd.IDKhuVucNo = kv.IDKhuVuc
        WHERE i.TgianRa IS NOT NULL;

        IF @IDPhieu IS NULL RETURN;

        -- 1. KIỂM TRA THẺ XE THÁNG (Ưu tiên số 1)
        -- Nếu cặp Khách - Xe này có thẻ tháng còn hạn, tổng tiền sẽ là 0
		DECLARE @IDTheXeThang VARCHAR(12);

		SELECT TOP 1 
			@IDTheXeThang = IDTheThang
		FROM TheXeThang
		WHERE IDKhachHangNo = @IDKH
		  AND IDXeNo = @BienSo
		  AND TrangThai = 1
		  AND NgayHetHan >= CAST(@Ra AS DATE)
		ORDER BY NgayHetHan DESC;

		IF @IDTheXeThang IS NOT NULL
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
            JOIN LoaiHinhTinhPhi lhtp ON bg.IDBangGia = lhtp.IDBangGiaNo
            WHERE bg.IDBaiDoNo = @IDBaiDo 
              AND bg.IDLoaiXeNo = @IDLoaiXe 
              AND lhtp.DonViThoiGian = N'Giờ'
              AND bg.HieuLuc = 1
            ORDER BY bg.IDBangGia DESC;

            -- Nếu không tìm thấy bảng giá, mặc định lấy 5000 để tránh lỗi logic
            SET @DonGia = ISNULL(@DonGia, 5000);
            SET @TongTien = @SoGio * @DonGia;
        END

        -- 3. TẠO HÓA ĐƠN
        DECLARE @SoHD INT;
        EXEC sp_SinhMa 'HoaDon', @SoHD OUTPUT;
        DECLARE @DateStr VARCHAR(10) = REPLACE(CONVERT(VARCHAR, GETDATE(), 103), '/', '');
        DECLARE @NewHoaDonID VARCHAR(20) = 'HD' + RIGHT('0000' + CAST(@SoHD AS VARCHAR), 4) + '_' + @DateStr;

        INSERT INTO HoaDon (IDHoaDon, ThanhTien, NgayTao, LoaiHoaDon)
        VALUES (@NewHoaDonID, @TongTien, GETDATE(), N'Vé lượt');
        
        -- 4. CẬP NHẬT NGƯỢC LẠI PHIẾU GIỮ XE
        UPDATE PhieuGiuXe 
        SET IDHoaDonNo = @NewHoaDonID 
        WHERE IDPhieuGiuXe = @IDPhieu;
        
        --tạo bảng thanh toán
        DECLARE @SoTT INT, @IDTT VARCHAR(12);
        EXEC sp_SinhMa 'ThanhToan', @SoTT OUTPUT;
        SET @IDTT = 'TT' + RIGHT('00000' + CAST(@SoTT AS VARCHAR), 5) + '_CK';

        insert into ThanhToan (IDThanhToan, IDHoaDonNo, PhuongThuc) Values
        (@IDTT, @NewHoaDonID, N'Chuyển khoản')

        DECLARE @IDDatCho VARCHAR(20);

		SELECT @IDDatCho = dc.IDDatCho
		FROM DatCho dc
		WHERE dc.IDChoDauNo = (
				SELECT IDChoDauNo FROM PhieuGiuXe WHERE IDPhieuGiuXe = @IDPhieu
			  )
		  AND dc.IDKhachHangNo = @IDKH
		  AND dc.IDXeNo = @BienSo
		ORDER BY dc.TgianBatDau DESC;

        -- Gen CTHD ID using sp_SinhMa
        DECLARE @SoCTHD INT, @IDCTHD VARCHAR(20);
        EXEC sp_SinhMa 'ChiTietHoaDon', @SoCTHD OUTPUT;
        
        -- Suffix like GenarateID.sql: CTHDxxxx_HDxxxx (extracted from HDxxxx_Date)
        DECLARE @HDSuffix VARCHAR(20) = @NewHoaDonID;
        IF CHARINDEX('_', @NewHoaDonID) > 0 
           SET @HDSuffix = SUBSTRING(@NewHoaDonID, 1, CHARINDEX('_', @NewHoaDonID)-1);
        
        SET @IDCTHD = 'CTHD' + RIGHT('0000' + CAST(@SoCTHD AS VARCHAR), 4) + '_' + @HDSuffix;

		-- Có thẻ tháng
		IF @IDTheXeThang IS NOT NULL
		BEGIN
			INSERT INTO ChiTietHoaDon (IDChiTietHoaDon, IDHoaDonNo, IDTheXeThangNo, TongTien)
			VALUES (@IDCTHD, @NewHoaDonID, @IDTheXeThang, @TongTien);
		END
		-- Có đặt chỗ
		ELSE IF @IDDatCho IS NOT NULL
		BEGIN
			INSERT INTO ChiTietHoaDon (IDChiTietHoaDon, IDHoaDonNo, IDDatChoNo, TongTien)
			VALUES (@IDCTHD, @NewHoaDonID, @IDDatCho, @TongTien);
		END
		-- Khách vãng lai
		ELSE
		BEGIN
			INSERT INTO ChiTietHoaDon (IDChiTietHoaDon, IDHoaDonNo, TongTien)
			VALUES (@IDCTHD, @NewHoaDonID, @TongTien);
		END
    END
END;
GO


	CREATE VIEW vw_BangGiaChiTiet
	AS
	SELECT
		bg.IDBangGia,
		bg.IDBaiDoNo,
		bg.IDLoaiXeNo,
		bg.TenBangGia,
		lhtp.IDLoaiHinhTinhPhi,
		lhtp.TenLoaiHinh,
		lhtp.DonViThoiGian,
		lhtp.GiaTien,
		kg.IDKhungGio,
		kg.TenKhungGio,
		kg.ThoiGianBatDau,
		kg.ThoiGianKetThuc
	FROM BangGia bg
	JOIN LoaiHinhTinhPhi lhtp 
		ON bg.IDBangGia = lhtp.IDBangGiaNo
	JOIN KhungGio kg 
		ON lhtp.IDLoaiHinhTinhPhi = kg.IDLoaiHinhTinhPhiNo
	WHERE bg.HieuLuc = 1;
	GO
	CREATE PROCEDURE sp_XemGiaDatCho
		@IDChoDau VARCHAR(12),
		@BienSoXe VARCHAR(12),
		@TgianBatDau DATETIME,
		@TgianKetThuc DATETIME
	AS
	BEGIN
		SET NOCOUNT ON;

		DECLARE @IDBaiDo VARCHAR(8);
		DECLARE @IDLoaiXe VARCHAR(10);
		DECLARE @SoGio INT;

		-- 1. Lấy bãi đỗ từ chỗ đỗ
		SELECT @IDBaiDo = bd.IDBaiDo
		FROM ChoDauXe cd
		JOIN KhuVuc kv ON cd.IDKhuVucNo = kv.IDKhuVuc
		JOIN BaiDo bd ON kv.IDBaiDoNo = bd.IDBaiDo
		WHERE cd.IDChoDauXe = @IDChoDau;

		-- 2. Lấy loại xe từ biển số
		SELECT @IDLoaiXe = IDLoaiXeNo
		FROM Xe
		WHERE BienSoXe = @BienSoXe;

		IF @IDBaiDo IS NULL OR @IDLoaiXe IS NULL
		BEGIN
			RAISERROR(N'Không xác định được bãi đỗ hoặc loại xe',16,1);
			RETURN;
		END

		-- 3. Số giờ gửi
		SET @SoGio = CEILING(DATEDIFF(MINUTE, @TgianBatDau, @TgianKetThuc) / 60.0);

		-- 4. Xác định khung giờ
		DECLARE @GioBatDau TIME = CAST(@TgianBatDau AS TIME);

		-- 5. Trả kết quả giá
		SELECT TOP 1
			TenBangGia,
			TenLoaiHinh,
			DonViThoiGian,
			GiaTien,
			TenKhungGio,
			@SoGio AS SoGio,
			CASE 
				WHEN DonViThoiGian = N'Giờ' 
					THEN GiaTien * @SoGio
				WHEN DonViThoiGian = N'Ngày' 
					THEN GiaTien * CEILING(@SoGio / 24.0)
				WHEN DonViThoiGian = N'Tháng' 
					THEN GiaTien
				ELSE GiaTien
			END AS TongTienDuKien
		FROM vw_BangGiaChiTiet
		WHERE IDBaiDoNo = @IDBaiDo
		  AND IDLoaiXeNo = @IDLoaiXe
		  AND @GioBatDau BETWEEN ThoiGianBatDau AND ThoiGianKetThuc;
	END;
	GO



IF OBJECT_ID('sp_DatChoVaThanhToanNhieuXe') IS NOT NULL
    DROP PROCEDURE sp_DatChoVaThanhToanNhieuXe;
GO
CREATE PROCEDURE sp_DatChoVaThanhToanNhieuXe
    @IDKhachHang   VARCHAR(12),
    @DanhSachXe    NVARCHAR(MAX),   -- '30A-999.99,51K-123.45'
    @DanhSachCho   NVARCHAR(MAX),   -- 'CD0001_B,CD0002_B'
    @TgianBatDau   DATETIME,
    @TgianKetThuc  DATETIME,
    @PhuongThuc    NVARCHAR(50),
    @MaVoucher     VARCHAR(20) = NULL  -- Mã voucher (tùy chọn)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @TongTien DECIMAL(18,2);
    DECLARE @GiamGia DECIMAL(18,2) = 0;
    DECLARE @IDVoucher VARCHAR(15) = NULL;

    /* ===============================
       1. TÁCH XE + CHỖ (THEO THỨ TỰ)
    =============================== */
    DECLARE @Xe TABLE (STT varchar(255), BienSoXe VARCHAR(20));
    DECLARE @Cho TABLE (STT varchar(255), IDChoDau VARCHAR(12));

    INSERT INTO @Xe
    SELECT ROW_NUMBER() OVER (ORDER BY (SELECT 1)), TRIM(value)
    FROM STRING_SPLIT(@DanhSachXe, ',')
    WHERE TRIM(value) <> '';

    INSERT INTO @Cho
    SELECT ROW_NUMBER() OVER (ORDER BY (SELECT 1)), TRIM(value)
    FROM STRING_SPLIT(@DanhSachCho, ',')
    WHERE TRIM(value) <> '';

    IF NOT EXISTS (SELECT 1 FROM @Xe)
        THROW 50010, N'Danh sách xe không hợp lệ', 1;

    IF (SELECT COUNT(*) FROM @Xe) <> (SELECT COUNT(*) FROM @Cho)
        THROW 50011, N'Số xe và số chỗ đậu phải bằng nhau', 1;

    /* ===============================
       2. KIỂM TRA THỜI GIAN
    =============================== */
    IF @TgianBatDau >= @TgianKetThuc
        THROW 50001, N'Thời gian không hợp lệ', 1;

    IF @TgianBatDau < GETDATE()
        THROW 50002, N'Không thể đặt chỗ trong quá khứ', 1;

    BEGIN TRY
        BEGIN TRANSACTION;

        /* ===============================
           3. KIỂM TRA XE THUỘC KHÁCH
        =============================== */
        IF EXISTS (
            SELECT 1
            FROM @Xe x
            WHERE NOT EXISTS (
                SELECT 1
                FROM KhachHang_Xe
                WHERE IDKhachHangNo = @IDKhachHang
                  AND IDXeNo = x.BienSoXe
            )
        )
            THROW 50005, N'Có xe không thuộc khách hàng', 1;

        /* ===============================
           4. KIỂM TRA CHỖ + TRÙNG LỊCH
        =============================== */
        IF EXISTS (
            SELECT 1
            FROM @Cho c
            JOIN ChoDauXe cd ON cd.IDChoDauXe = c.IDChoDau
            WHERE cd.TrangThai IN (N'Bảo trì', N'Tạm dừng', N'Đóng cửa')
        )
            THROW 50003, N'Có chỗ đậu không khả dụng', 1;

        IF EXISTS (
            SELECT 1
            FROM @Cho c
            JOIN DatCho d ON d.IDChoDauNo = c.IDChoDau
            WHERE d.TrangThai IN (N'Đã đặt', N'Đã thanh toán')
              AND (@TgianBatDau < d.TgianKetThuc AND @TgianKetThuc > d.TgianBatDau)
        )
            THROW 50004, N'Có chỗ đậu bị trùng lịch', 1;

		/* ===============================
		   5. TÍNH TIỀN THEO BẢNG GIÁ (KIỂM TRA OVERLAP, HỖ TRỢ QUA NỬA ĐÊM)
		=============================== */
		DECLARE @GioBat TIME = CAST(@TgianBatDau AS TIME);
		DECLARE @GioKet TIME = CAST(@TgianKetThuc AS TIME);
		declare @IDThanhToan varchar(100)


		DECLARE @TienXe TABLE (
            IDKhachHang    VARCHAR(12),
            BienSoXe       VARCHAR(20),
            IDChoDau       VARCHAR(12),
			TongTien       DECIMAL(18,2)
		);


		INSERT INTO @TienXe (IDKhachHang, BienSoXe, IDChoDau, TongTien)
		SELECT
            @IDKhachHang,
            x.BienSoXe,
            c.IDChoDau,
			CASE 
				WHEN bg.DonViThoiGian = N'Giờ'
					THEN bg.GiaTien *
						 CEILING(DATEDIFF(MINUTE, @TgianBatDau, @TgianKetThuc) / 60.0)
				WHEN bg.DonViThoiGian = N'Ngày'
					THEN bg.GiaTien *
						 CEILING(DATEDIFF(MINUTE, @TgianBatDau, @TgianKetThuc) / 1440.0)
				WHEN bg.DonViThoiGian = N'Tháng'
					THEN bg.GiaTien
				ELSE bg.GiaTien
			END
		FROM @Xe x
		JOIN @Cho c ON x.STT = c.STT
		JOIN Xe xe ON xe.BienSoXe = x.BienSoXe
		JOIN ChoDauXe cd ON cd.IDChoDauXe = c.IDChoDau
		JOIN KhuVuc kv ON cd.IDKhuVucNo = kv.IDKhuVuc
		JOIN BaiDo bd ON kv.IDBaiDoNo = bd.IDBaiDo
		JOIN vw_BangGiaChiTiet bg
			ON bg.IDBaiDoNo  = bd.IDBaiDo
		   AND bg.IDLoaiXeNo = xe.IDLoaiXeNo
		WHERE
		(
			/* TH1: khung bình thường (start <= end) -> check nếu khoảng đặt chỗ có 1 điểm trong khung */
			(bg.ThoiGianBatDau <= bg.ThoiGianKetThuc
			 AND (
				   -- start rơi trong khung
				   @GioBat BETWEEN bg.ThoiGianBatDau AND bg.ThoiGianKetThuc
				   -- hoặc end rơi trong khung
				   OR @GioKet BETWEEN bg.ThoiGianBatDau AND bg.ThoiGianKetThuc
				   -- hoặc khung nằm hoàn toàn trong khoảng đặt chỗ (ví dụ đặt dài)
				   OR (bg.ThoiGianBatDau BETWEEN @GioBat AND @GioKet)
				 )
			)
			OR
			/* TH2: khung quấn qua nửa đêm (start > end) */
			(bg.ThoiGianBatDau > bg.ThoiGianKetThuc
			 AND (
				   -- start nằm sau thời điểm bắt đầu khung (vd 22:00 → 06:00, start >= 22:00)
				   (@GioBat >= bg.ThoiGianBatDau)
				   -- hoặc end nằm trước thời điểm kết thúc khung (vd end <= 06:00)
				   OR (@GioKet <= bg.ThoiGianKetThuc)
				   -- hoặc khung nằm trong khoảng đặt chỗ (các trường hợp khác)
				   OR (bg.ThoiGianBatDau BETWEEN @GioBat AND @GioKet)
				 )
			)
		);
		
        -- Cập nhật giá về 0 nếu có Thẻ Xe Tháng hợp lệ
        -- Logic: Tìm thẻ tháng khớp KH, Xe, còn hạn, trạng thái Active
        UPDATE tx
        SET TongTien = 0
        FROM @TienXe tx
        WHERE EXISTS (
            SELECT 1 
            FROM TheXeThang txt
            WHERE txt.IDKhachHangNo = tx.IDKhachHang
              AND txt.IDXeNo = tx.BienSoXe
              AND txt.TrangThai = 1
              AND CAST(GETDATE() AS DATE) <= txt.NgayHetHan
        );

		-- lấy tổng
		SELECT @TongTien = ISNULL(SUM(TongTien), 0) FROM @TienXe;

		IF @TongTien = 0 AND NOT EXISTS (SELECT 1 FROM @TienXe)
		BEGIN
            -- Chỉ warning nếu không tìm được dòng nào tính tiền (chứ không phải do thẻ tháng = 0)
			PRINT N'WARNING: Tổng tiền tính được là 0 và không có dữ liệu tính phí. Kiểm tra lại vw_BangGiaChiTiet cho (BaiDo,LoaiXe) hoặc thêm khung giá phù hợp (ví dụ khung đêm).';
		END


        /* ===============================
           5b. KIỂM TRA VOUCHER
        =============================== */
        IF @MaVoucher IS NOT NULL
        BEGIN
            SELECT TOP 1
                @IDVoucher = IDVoucher,
                @GiamGia   = GiaTri
            FROM Voucher
            WHERE MaCode = @MaVoucher
              AND TrangThai = 1
              AND SoLuong > 0
              AND HanSuDung >= CAST(GETDATE() AS DATE);

            IF @IDVoucher IS NULL
                THROW 50020, N'Voucher không hợp lệ hoặc đã hết hạn', 1;

            -- Giảm tiền
            SET @TongTien = CASE WHEN @TongTien - @GiamGia < 0 THEN 0 ELSE @TongTien - @GiamGia END;

            -- Giảm số lượng voucher
            UPDATE Voucher
            SET SoLuong = SoLuong - 1
            WHERE IDVoucher = @IDVoucher;
        END

        /* ===============================
           6. TẠO HÓA ĐƠN (TRIGGER TỰ SINH ID)
        =============================== */
		DECLARE @IDHoaDon VARCHAR(20);

		-- Tạo hóa đơn
		EXEC sp_ThemHoaDon
			@ThanhTien = @TongTien,
			@LoaiHoaDon = N'Đặt chỗ',
			@IDVoucher = @IDVoucher;

		-- Lấy ID hóa đơn vừa tạo (an toàn trong transaction)
		SELECT TOP 1 @IDHoaDon = IDHoaDon
		FROM HoaDon
		ORDER BY NgayTao DESC;

        -- (Removed direct sp_ThemChiTietHoaDon here, moved to loop)

        /* ===============================
           8. THANH TOÁN (Tạo thanh toán cho cả hóa đơn)
        =============================== */
		-- Thay thế INSERT trực tiếp bằng Procedure
		EXEC sp_ThemThanhToan
			@IDHoaDonNo = @IDHoaDon,
			@PhuongThuc = @PhuongThuc;
		
		-- Lấy ID Thanh toán vừa tạo và Cập nhật trạng thái thành 1 (Đã thanh toán) vì proc mặc định là 0
		SELECT TOP 1 @IDThanhToan = IDThanhToan 
		FROM ThanhToan 
		WHERE IDHoaDonNo = @IDHoaDon 
		ORDER BY NgayThanhToan DESC;

		UPDATE ThanhToan 
		SET TrangThai = 1 
		WHERE IDThanhToan = @IDThanhToan;

        /* ===============================
           9. ĐẶT CHỖ & CHI TIẾT HÓA ĐƠN
        =============================== */
		-- Thay thế Bulk Insert bằng Cursor để gọi sp_ThemDatCho cho từng dòng
        DECLARE @Cur_BienSoXe VARCHAR(20);
        DECLARE @Cur_IDChoDau VARCHAR(12);
        
        DECLARE cur_DatCho CURSOR FOR 
        SELECT x.BienSoXe, c.IDChoDau
        FROM @Xe x
        JOIN @Cho c ON x.STT = c.STT;

        OPEN cur_DatCho;
        FETCH NEXT FROM cur_DatCho INTO @Cur_BienSoXe, @Cur_IDChoDau;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            -- 9a. Gọi SP thêm đặt chỗ (Trạng thái mặc định: 'Đang chờ duyệt')
            EXEC sp_ThemDatCho
                @IDKhachHangNo = @IDKhachHang,
                @IDXeNo = @Cur_BienSoXe,
                @IDChoDauNo = @Cur_IDChoDau,
                @IDNhanVienNo = NULL, -- Đặt online không có nhân viên
                @TgianBatDau = @TgianBatDau,
                @TgianKetThuc = @TgianKetThuc;

            -- 9b. Lấy IDDatCho vừa tạo để dùng cho update & CTHD
            -- Tìm record vừa tạo để update (dựa vào key unique logic: KH, Xe, Cho, Time)
            DECLARE @NewIDDatCho VARCHAR(20);
            
            SELECT @NewIDDatCho = IDDatCho
            FROM DatCho
            WHERE IDKhachHangNo = @IDKhachHang
              AND IDXeNo = @Cur_BienSoXe
              AND IDChoDauNo = @Cur_IDChoDau
              AND TgianBatDau = @TgianBatDau
              AND TrangThai = N'Đang chờ duyệt';

            -- Cập nhật trạng thái thành 'Đã thanh toán'
            UPDATE DatCho
            SET TrangThai = N'Đang chờ duyệt'
            WHERE IDDatCho = @NewIDDatCho;

            -- 9c. Xử lý Chi Tiết Hóa Đơn (Kiểm tra Thẻ Tháng)
            DECLARE @IDTheXeThang VARCHAR(12) = NULL;
            DECLARE @ItemPrice DECIMAL(18,2) = 0;
            DECLARE @FinalIDDatCho VARCHAR(20) = @NewIDDatCho; -- Mặc định link tới Đặt Chỗ

            -- Kiểm tra có thẻ tháng không
            SELECT TOP 1 @IDTheXeThang = IDTheThang
            FROM TheXeThang
            WHERE IDKhachHangNo = @IDKhachHang
              AND IDXeNo = @Cur_BienSoXe
              AND TrangThai = 1
              AND CAST(GETDATE() AS DATE) <= NgayHetHan;

            -- Lấy giá tiền cho item này từ bảng @TienXe
            SELECT @ItemPrice = ISNULL(TongTien, 0)
            FROM @TienXe
            WHERE BienSoXe = @Cur_BienSoXe AND IDChoDau = @Cur_IDChoDau;

            -- Logic User: "nếu user có thexethang thì dùng id đó"
            -- Nếu có thẻ tháng: IDTheXeThangNo = ID, IDDatChoNo = NULL (hoặc giữ IDDatCho nếu muốn tracking, nhưng user yêu cầu dùng ID thẻ)
            IF @IDTheXeThang IS NOT NULL
            BEGIN
                SET @FinalIDDatCho = NULL; -- User yêu cầu dùng ID thẻ thay thế
                SET @ItemPrice = 0;        -- Miễn phí nếu có thẻ tháng (đã update trong @TienXe rồi nhưng set lại cho chắc)
            END

            -- Insert ChiTietHoaDon
		    EXEC sp_ThemChiTietHoaDon
			    @IDTheXeThangNo = @IDTheXeThang,
			    @IDDatChoNo = @FinalIDDatCho,
			    @IDHoaDonNo = @IDHoaDon,
			    @TongTien = @ItemPrice;

            FETCH NEXT FROM cur_DatCho INTO @Cur_BienSoXe, @Cur_IDChoDau;
        END;

        CLOSE cur_DatCho;
        DEALLOCATE cur_DatCho;


        COMMIT;

        /* ===============================
           10. TRẢ KẾT QUẢ
        =============================== */
        SELECT
            @IDHoaDon    AS IDHoaDon,
            @IDThanhToan AS IDThanhToan,
            @TongTien    AS TongTien,
            @GiamGia     AS GiamGia,
            @IDVoucher   AS IDVoucher,
            N'Đặt chỗ & thanh toán nhiều xe – nhiều chỗ thành công' AS TrangThai;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;
        THROW;
    END CATCH
END



GO

-- =============================================
-- Bước 1: Thêm tài khoản & Khách hàng
-- =============================================
PRINT N'--- 1. Thêm Tài khoản & Khách hàng ---';
EXEC sp_ThemTaiKhoanKhachHang 'tung_test_auto', '123', N'Nguyễn Auto Tùng', '0911222999', '123199999', N'Hà Nội';

-- Kiểm tra kết quả
select * from TaiKhoan
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
    EXEC sp_KhachHangDatCho @NewKHID_3, @BienSoXeTest, @ChoDauTest, '2026-12-01 08:00', '2026-12-01 17:00';

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
DECLARE @DanhSachXe  NVARCHAR(MAX) = '30A-888.88,51K-123.45';
DECLARE @DanhSachCho NVARCHAR(MAX) = 'CD0001_B,CD0002_B';
DECLARE @BatDau  DATETIME = DATEADD(DAY, 1, '2026-01-16 17:33:05');
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
select * from DatCho






------
EXEC sp_XemGiaDatCho 'CD0001_B', '30A-999.99', '2026-11-01 08:00', '2026-11-01 17:00';
EXEC sp_XemGiaDatCho 'CD0002_B', '51K-123.45', '2026-11-01 08:00', '2026-11-01 17:00';

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
    SELECT TenChoDau, TrangThai FROM ChoDauXe WHERE IDChoDauXe = 'DC0002_11012026';
END
go

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
    DECLARE @BienSoXe VARCHAR(20) = '30A-888.88';
    
    -- Tìm phiếu giữ xe đang mở của xe này
    DECLARE @IDPhieu VARCHAR(15) = (SELECT MAX(IDPhieuGiuXe) FROM PhieuGiuXe WHERE IDXeNo = @BienSoXe AND TgianRa IS NULL);

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

GO
-- =============================================
-- Bước 7: Test Đăng ký thẻ tháng 
-- =============================================
PRINT N'--- 7. Test Thẻ tháng ---';
BEGIN
    DECLARE @NewKHID_7 VARCHAR(12);
    SELECT TOP 1 @NewKHID_7 = IDKhachHang FROM KhachHang WHERE HoTen = N'Nguyễn Auto Tùng' ORDER BY IDKhachHang DESC;
    
    EXEC sp_DangKyTheXeThang
        @IDKhachHang = @NewKHID_7,
        @IDBaiDo = 'BD001',
        @IDXe = '30A-888.88',
	    @TenTheXe = N'Thẻ xe tháng Test',
        @SoThang = 1;

    -- Xem kết quả
    SELECT * FROM TheXeThang WHERE IDKhachHangNo = @NewKHID_7;
END
select * from HoaDon
select * from ChiTietHoaDon

--- Đặt chổ nhiều xe 
SELECT dbo.fn_LayGiaTheThang('59A-12345', 'BD001') AS GiaThang;
select * from TheXeThang
select * from KhachHang_Xe
select * from khachhang
select * from HoaDon
select * from ChiTietHoaDon
DECLARE @IDKH VARCHAR(12) = 'KH00002_TX';
DECLARE @IDXE VARCHAR(20) = '30A-888.88';
DECLARE @IDBaiDo VARCHAR(8) = 'BD001';
EXEC sp_DangKyTheXeThang
    @IDKhachHang = @IDKH,
    @IDXe = @IDXE,
    @IDBaiDo = @IDBaiDo,
    @TenTheXe = N'Thẻ xe tháng Toyota',
    @SoThang = 3;
exec sp_GiaHanTheXeThang
	@IDTheThang = 'TXT003_3T',
	@SoThang = 2,
	@IDBaiDo = 'BD001'
exec sp_HuyTheXeThang
		@IDTheThang = 'TXT003_3T'
select * from LichLamViec
exec sp_PhanLichLamViec
    @IDNhanVien = 'NV001_BV',
    @IDCaLam    = 'CL01_S',
    @IDBaiDo    = 'BD001',
    @NgayBatDau   = '2026-02-11',
    @NgayKetThuc  = '2026-02-15';
exec sp_TraCuuLichSuXe @BienSo = '59A-12345'
exec sp_ThongKeChiTietKhachHang @TuKhoa = N'tỉnh'
print dbo.f_TongDoanhThuThang(1,2026)
exec sp_BaoCaoThongKeTongHop 
    @NgayBatDau = '2025-01-11', 
    @NgayKetThuc = '2026-01-12'