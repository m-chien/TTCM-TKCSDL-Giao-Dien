IF EXISTS (SELECT * FROM sys.databases WHERE name = 'ParkingLot')
BEGIN
    USE master;
    ALTER DATABASE ParkingLot SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE ParkingLot;
END
GO

CREATE DATABASE ParkingLot;
GO

USE ParkingLot;
GO
-- 1. BẢNG DANH MỤC & CẤU HÌNH CƠ BẢN
CREATE TABLE VaiTro (
    ID INT PRIMARY KEY IDENTITY(1,1),
    TenVaiTro NVARCHAR(50) NOT NULL
);

CREATE TABLE LoaiXe (
    ID INT PRIMARY KEY IDENTITY(1,1),
    TenLoaiXe NVARCHAR(50) NOT NULL
);

-- 2. HỆ THỐNG TÀI KHOẢN
CREATE TABLE TaiKhoan (
    ID INT PRIMARY KEY IDENTITY(1,1),
    IDVaiTro INT FOREIGN KEY REFERENCES VaiTro(ID),
    TenDangNhap VARCHAR(50) UNIQUE NOT NULL,
    MatKhau VARCHAR(255) NOT NULL,
    AnhDaiDien NVARCHAR(255),
    TrangThai BIT DEFAULT 1
);

CREATE TABLE KhachHang (
    ID INT PRIMARY KEY IDENTITY(1,1),
    IDTaiKhoan INT FOREIGN KEY REFERENCES TaiKhoan(ID),
    HoTen NVARCHAR(100),
    SDT VARCHAR(15),
    CCCD VARCHAR(20),
    BangLaiXe VARCHAR(20),
    DiaChi NVARCHAR(255),
    LoaiKH NVARCHAR(50), -- Vãng lai/Thường xuyên
    SoTK VARCHAR(20),
    TenNganHang NVARCHAR(50)
);

CREATE TABLE NhanVien (
    ID INT PRIMARY KEY IDENTITY(1,1),
    IDTaiKhoan INT FOREIGN KEY REFERENCES TaiKhoan(ID),
    TenNhanVien NVARCHAR(100),
    SDT VARCHAR(15),
    Email VARCHAR(100),
    ChucVu NVARCHAR(50),
    LuongCB DECIMAL(18,2)
);

CREATE TABLE ChuBaiXe (
    ID INT PRIMARY KEY IDENTITY(1,1),
    IDTaiKhoan INT FOREIGN KEY REFERENCES TaiKhoan(ID),
    TenChuBai NVARCHAR(100),
    SDT VARCHAR(15),
    Email VARCHAR(100),
    CCCD VARCHAR(20),
    DiaChi NVARCHAR(255)
);

-- 3. QUẢN LÝ XE
CREATE TABLE Xe (
    BienSoXe VARCHAR(20) PRIMARY KEY, -- Chọn Biển số làm PK hoặc Unique
    IDLoaiXe INT FOREIGN KEY REFERENCES LoaiXe(ID),
    TenXe NVARCHAR(100),
    Hang NVARCHAR(50),
    MauSac NVARCHAR(50),
    HinhAnh NVARCHAR(255)
);

CREATE TABLE KhachHang_Xe (
    ID INT PRIMARY KEY IDENTITY(1,1),
    IDKhachHang INT FOREIGN KEY REFERENCES KhachHang(ID),
    IDXe VARCHAR(20) FOREIGN KEY REFERENCES Xe(BienSoXe),
    LoaiSoHuu NVARCHAR(50) -- Ví dụ: Chính chủ, Thuê
);

-- 4. CẤU TRÚC BÃI ĐỖ
CREATE TABLE BaiDo (
    ID INT PRIMARY KEY IDENTITY(1,1),
    IDChuBai INT FOREIGN KEY REFERENCES ChuBaiXe(ID),
    TenBai NVARCHAR(100),
    ViTri NVARCHAR(255),
    SucChua INT,
    TrangThai NVARCHAR(50),
    HinhAnh NVARCHAR(255)
);

CREATE TABLE KhuVuc (
    ID INT PRIMARY KEY IDENTITY(1,1),
    IDBaiDo INT FOREIGN KEY REFERENCES BaiDo(ID),
    TenKhuVuc NVARCHAR(50),
    SucChua INT,
    HinhAnh NVARCHAR(255)
);

CREATE TABLE ChoDauXe (
    ID INT PRIMARY KEY IDENTITY(1,1),
    IDKhuVuc INT FOREIGN KEY REFERENCES KhuVuc(ID),
    TenChoDau NVARCHAR(20),
    KichThuoc NVARCHAR(50),
    TrangThai NVARCHAR(50) -- Trống/Đã đặt/Đang đỗ/Bảo trì
);

CREATE TABLE ThietBi (
    ID INT PRIMARY KEY IDENTITY(1,1),
    IDKhuVuc INT FOREIGN KEY REFERENCES KhuVuc(ID),
    TenThietBi NVARCHAR(100),
    LoaiThietBi NVARCHAR(50), -- Camera, Cảm biến, Barrier
    TrangThai NVARCHAR(50),
    NgayCaiDat DATE,
    GiaLapDat DECIMAL(18,2)
);

-- 5. GIÁ VÀ DỊCH VỤ
CREATE TABLE BangGia (
    ID INT PRIMARY KEY IDENTITY(1,1),
    IDBaiDo INT FOREIGN KEY REFERENCES BaiDo(ID),
    IDLoaiXe INT FOREIGN KEY REFERENCES LoaiXe(ID),
    TenBangGia NVARCHAR(100), -- Ví dụ: "Bảng giá 2025 - Xe Máy"
    HieuLuc BIT DEFAULT 1 -- Để Admin có thể tạm ẩn bảng giá này đi
);

-- 2. Bảng Con: LOẠI HÌNH TÍNH PHÍ (Chi tiết giá)
-- Chứa Giá tiền và Đơn vị tính. Liên kết về Bảng Giá.
CREATE TABLE LoaiHinhTinhPhi (
    ID INT PRIMARY KEY IDENTITY(1,1),
    IDBangGia INT FOREIGN KEY REFERENCES BangGia(ID), -- Link ngược về cha
    TenLoaiHinh NVARCHAR(100), -- Ví dụ: "Vé lượt ngày", "Vé tháng", "Vé qua đêm"
    DonViThoiGian NVARCHAR(50), -- Ví dụ: "Giờ", "Lượt", "Tháng"
    GiaTien DECIMAL(18,2) NOT NULL -- Giá tiền nằm ở đây là CHUẨN nhất
);

-- 3. Bảng Cháu: KHUNG GIỜ
-- Quy định khung giờ áp dụng cho Loại hình bên trên (nếu có)
CREATE TABLE KhungGio (
    ID INT PRIMARY KEY IDENTITY(1,1),
    IDLoaiHinhTinhPhi INT FOREIGN KEY REFERENCES LoaiHinhTinhPhi(ID), -- Link ngược về Loại hình
    TenKhungGio NVARCHAR(50), -- Ví dụ: "Ca Sáng", "Ca Đêm"
    ThoiGianBatDau TIME,
    ThoiGianKetThuc TIME
);

CREATE TABLE TheXeThang (
    ID INT PRIMARY KEY IDENTITY(1,1),
    IDKhachHang_Xe INT FOREIGN KEY REFERENCES KhachHang_Xe(ID),
    TenTheXe NVARCHAR(100),
    NgayDangKy DATE,
    NgayHetHan DATE,
    TrangThai BIT
);

CREATE TABLE Voucher (
    ID INT PRIMARY KEY IDENTITY(1,1),
    IDBaiDo INT FOREIGN KEY REFERENCES BaiDo(ID),
    TenVoucher NVARCHAR(100),
    GiaTri DECIMAL(18,2), -- Số tiền giảm hoặc %
    HanSuDung DATE,
    SoLuong INT,
    TrangThai BIT,
    MaCode VARCHAR(20) UNIQUE
);

-- 6. NGHIỆP VỤ VÀO/RA (CORE)
CREATE TABLE DatCho (
    ID INT PRIMARY KEY IDENTITY(1,1),
    IDKhachHang INT FOREIGN KEY REFERENCES KhachHang(ID),
    IDNhanVien INT FOREIGN KEY REFERENCES NhanVien(ID), -- Có thể null nếu đặt online
    IDChoDau INT FOREIGN KEY REFERENCES ChoDauXe(ID),
    TgianBatDau DATETIME,
    TgianKetThuc DATETIME,
    TrangThai NVARCHAR(50) -- Đã đặt/Đã hủy/Hoàn thành
);

CREATE TABLE HoaDon (
    ID INT PRIMARY KEY IDENTITY(1,1),
    ThanhTien DECIMAL(18,2),
    NgayTao DATETIME DEFAULT GETDATE(),
    LoaiHoaDon NVARCHAR(50), -- Hóa đơn lượt/Tháng/Phạt
    IDVoucher INT FOREIGN KEY REFERENCES Voucher(ID)
);

CREATE TABLE PhieuGiuXe (
    ID INT PRIMARY KEY IDENTITY(1,1),
    IDXe VARCHAR(20) FOREIGN KEY REFERENCES Xe(BienSoXe),
    IDChoDau INT FOREIGN KEY REFERENCES ChoDauXe(ID),
    IDNhanVien INT FOREIGN KEY REFERENCES NhanVien(ID),
    IDHoaDon INT FOREIGN KEY REFERENCES HoaDon(ID),
    TgianVao DATETIME,
    TgianRa DATETIME,
    TrangThai NVARCHAR(50) -- Đang gửi/Đã lấy
);

CREATE TABLE ChiTietHoaDon (
    ID INT PRIMARY KEY IDENTITY(1,1),
    IDTheXeThang INT FOREIGN KEY REFERENCES TheXeThang(ID), -- Nếu thanh toán thẻ tháng
    IDDatCho INT FOREIGN KEY REFERENCES DatCho(ID),         -- Nếu thanh toán đặt chỗ
    IDHoaDon INT FOREIGN KEY REFERENCES HoaDon(ID),
    TongTien DECIMAL(18,2)
);

CREATE TABLE ThanhToan (
    ID INT PRIMARY KEY IDENTITY(1,1),
    IDHoaDon INT FOREIGN KEY REFERENCES HoaDon(ID),
    PhuongThuc NVARCHAR(50), -- Tiền mặt/Thẻ/QR
    TrangThai BIT, -- Thành công/Thất bại
    NgayThanhToan DATETIME DEFAULT GETDATE()
);

-- 7. CÁC BẢNG PHỤ TRỢ (Lịch làm việc, Sự cố, Đánh giá)
CREATE TABLE CaLam (
    ID INT PRIMARY KEY IDENTITY(1,1),
    TenCa NVARCHAR(50),
    TgianBatDau TIME,
    TgianKetThuc TIME,
    HeSoLuong FLOAT
);

CREATE TABLE LichLamViec (
    ID INT PRIMARY KEY IDENTITY(1,1),
    IDNhanVien INT FOREIGN KEY REFERENCES NhanVien(ID),
    IDCaLam INT FOREIGN KEY REFERENCES CaLam(ID),
    IDBaiDo INT FOREIGN KEY REFERENCES BaiDo(ID),
    NgayBatDau DATE,
    NgayKetThuc DATE,
    TrangThai BIT,
    SoNgayDaLam INT
);

CREATE TABLE SuCo (
    ID INT PRIMARY KEY IDENTITY(1,1),
    IDNhanVien INT FOREIGN KEY REFERENCES NhanVien(ID),
    IDThietBi INT FOREIGN KEY REFERENCES ThietBi(ID),
    MoTa NVARCHAR(MAX),
    MucDo NVARCHAR(50), -- Nhẹ/Nghiêm trọng
    TrangThaiXuLy NVARCHAR(50)
);

CREATE TABLE DanhGia (
    ID INT PRIMARY KEY IDENTITY(1,1),
    IDKhachHang INT FOREIGN KEY REFERENCES KhachHang(ID),
    IDHoaDon INT FOREIGN KEY REFERENCES HoaDon(ID),
    NoiDung NVARCHAR(MAX),
    DiemDanhGia INT, -- 1 đến 5 sao
    NgayDanhGia DATETIME DEFAULT GETDATE()
);
--- 1. Ràng buộc cơ bản về sức chứa (ngăn giá trị vô lý)
-- 1. Ràng buộc sức chứa > 0
ALTER TABLE BaiDo
ADD CONSTRAINT CK_BaiDo_SucChua CHECK (SucChua > 0);

ALTER TABLE KhuVuc
ADD CONSTRAINT CK_KhuVuc_SucChua CHECK (SucChua > 0);

-- 2. Ràng buộc trạng thái (enum-like)
ALTER TABLE BaiDo
ADD CONSTRAINT CK_BaiDo_TrangThai 
CHECK (TrangThai IN (N'Hoạt động', N'Đóng cửa', N'Bảo trì', N'Tạm dừng'));

ALTER TABLE ChoDauXe
ADD CONSTRAINT CK_ChoDauXe_TrangThai 
CHECK (TrangThai IN (N'Trống', N'Đã đặt', N'Đang đỗ', N'Bảo trì'));

ALTER TABLE PhieuGiuXe
ADD CONSTRAINT CK_PhieuGiuXe_TrangThai 
CHECK (TrangThai IN (N'Đang gửi', N'Đã lấy', N'Quá hạn', N'Mất vé'));

ALTER TABLE DatCho
ADD CONSTRAINT CK_DatCho_TrangThai 
CHECK (TrangThai IN (N'Đã đặt', N'Đã hủy', N'Hoàn thành', N'Quá hạn'));

-- 3. Ràng buộc thời gian logic
ALTER TABLE DatCho
ADD CONSTRAINT CK_DatCho_ThoiGian 
CHECK (TgianKetThuc > TgianBatDau);

ALTER TABLE PhieuGiuXe
ADD CONSTRAINT CK_PhieuGiuXe_ThoiGian 
CHECK (TgianRa IS NULL OR TgianRa > TgianVao);

ALTER TABLE KhungGio
ADD CONSTRAINT CK_KhungGio_ThoiGian 
CHECK (ThoiGianKetThuc > ThoiGianBatDau);

ALTER TABLE CaLam
ADD CONSTRAINT CK_CaLam_ThoiGian 
CHECK (TgianKetThuc > TgianBatDau);

-- 4. Ràng buộc giá tiền & giá trị tài chính (>= 0)
ALTER TABLE LoaiHinhTinhPhi
ADD CONSTRAINT CK_LoaiHinhTinhPhi_GiaTien 
CHECK (GiaTien >= 0);

ALTER TABLE HoaDon
ADD CONSTRAINT CK_HoaDon_ThanhTien 
CHECK (ThanhTien >= 0);

ALTER TABLE ChiTietHoaDon
ADD CONSTRAINT CK_ChiTietHoaDon_TongTien 
CHECK (TongTien >= 0);

ALTER TABLE Voucher
ADD CONSTRAINT CK_Voucher_GiaTri 
CHECK (GiaTri >= 0);

-- 5. Ràng buộc điểm đánh giá
ALTER TABLE DanhGia
ADD CONSTRAINT CK_DanhGia_DiemDanhGia 
CHECK (DiemDanhGia BETWEEN 1 AND 5);

-- 6. Ràng buộc lương & hệ số lương
ALTER TABLE NhanVien
ADD CONSTRAINT CK_NhanVien_LuongCB 
CHECK (LuongCB >= 0);

ALTER TABLE CaLam
ADD CONSTRAINT CK_CaLam_HeSoLuong 
CHECK (HeSoLuong >= 1.0);

-- 7. Các DEFAULT hữu ích (nếu chưa có)

ALTER TABLE TheXeThang
ADD CONSTRAINT DF_TheXeThang_TrangThai DEFAULT 1 FOR TrangThai;



ALTER TABLE Voucher
ADD CONSTRAINT DF_Voucher_TrangThai DEFAULT 1 FOR TrangThai;

ALTER TABLE ThanhToan
ADD CONSTRAINT DF_ThanhToan_TrangThai DEFAULT 1 FOR TrangThai;  -- 1 = thành công

ALTER TABLE LichLamViec
ADD CONSTRAINT DF_LichLamViec_TrangThai DEFAULT 0 FOR TrangThai; -- chờ duyệt



-- =============================================================================
-- PHẦN BỔ SUNG: Ràng buộc FOREIGN KEY với ON DELETE / ON UPDATE
-- Chèn toàn bộ phần này vào CUỐI script, sau tất cả CREATE TABLE và CHECK/DEFAULT
-- =============================================================================

-- 2. HỆ THỐNG TÀI KHOẢN
ALTER TABLE TaiKhoan
ADD CONSTRAINT FK_TaiKhoan_VaiTro 
    FOREIGN KEY (IDVaiTro) REFERENCES VaiTro(ID)
    ON DELETE NO ACTION 
    ON UPDATE NO ACTION;

ALTER TABLE KhachHang
ADD CONSTRAINT FK_KhachHang_TaiKhoan 
    FOREIGN KEY (IDTaiKhoan) REFERENCES TaiKhoan(ID)
    ON DELETE CASCADE 
    ON UPDATE CASCADE;

ALTER TABLE NhanVien
ADD CONSTRAINT FK_NhanVien_TaiKhoan 
    FOREIGN KEY (IDTaiKhoan) REFERENCES TaiKhoan(ID)
    ON DELETE CASCADE 
    ON UPDATE CASCADE;

ALTER TABLE ChuBaiXe
ADD CONSTRAINT FK_ChuBaiXe_TaiKhoan 
    FOREIGN KEY (IDTaiKhoan) REFERENCES TaiKhoan(ID)
    ON DELETE CASCADE 
    ON UPDATE CASCADE;

-- 3. QUẢN LÝ XE
ALTER TABLE Xe
ADD CONSTRAINT FK_Xe_LoaiXe 
    FOREIGN KEY (IDLoaiXe) REFERENCES LoaiXe(ID)
    ON DELETE NO ACTION 
    ON UPDATE NO ACTION;

ALTER TABLE KhachHang_Xe
ADD CONSTRAINT FK_KhachHang_Xe_KhachHang 
    FOREIGN KEY (IDKhachHang) REFERENCES KhachHang(ID)
    ON DELETE CASCADE 
    ON UPDATE CASCADE;

ALTER TABLE KhachHang_Xe
ADD CONSTRAINT FK_KhachHang_Xe_Xe 
    FOREIGN KEY (IDXe) REFERENCES Xe(BienSoXe)
    ON DELETE NO ACTION 
    ON UPDATE CASCADE;

-- 4. CẤU TRÚC BÃI ĐỖ
ALTER TABLE BaiDo
ADD CONSTRAINT FK_BaiDo_ChuBaiXe 
    FOREIGN KEY (IDChuBai) REFERENCES ChuBaiXe(ID)
    ON DELETE NO ACTION 
    ON UPDATE NO ACTION;

ALTER TABLE KhuVuc
ADD CONSTRAINT FK_KhuVuc_BaiDo 
    FOREIGN KEY (IDBaiDo) REFERENCES BaiDo(ID)
    ON DELETE CASCADE 
    ON UPDATE CASCADE;

ALTER TABLE ChoDauXe
ADD CONSTRAINT FK_ChoDauXe_KhuVuc 
    FOREIGN KEY (IDKhuVuc) REFERENCES KhuVuc(ID)
    ON DELETE CASCADE 
    ON UPDATE CASCADE;

ALTER TABLE ThietBi
ADD CONSTRAINT FK_ThietBi_KhuVuc 
    FOREIGN KEY (IDKhuVuc) REFERENCES KhuVuc(ID)
    ON DELETE CASCADE 
    ON UPDATE CASCADE;

-- 5. GIÁ VÀ DỊCH VỤ
ALTER TABLE BangGia
ADD CONSTRAINT FK_BangGia_BaiDo 
    FOREIGN KEY (IDBaiDo) REFERENCES BaiDo(ID)
    ON DELETE CASCADE 
    ON UPDATE CASCADE;

ALTER TABLE BangGia
ADD CONSTRAINT FK_BangGia_LoaiXe 
    FOREIGN KEY (IDLoaiXe) REFERENCES LoaiXe(ID)
    ON DELETE NO ACTION 
    ON UPDATE NO ACTION;

ALTER TABLE LoaiHinhTinhPhi
ADD CONSTRAINT FK_LoaiHinhTinhPhi_BangGia 
    FOREIGN KEY (IDBangGia) REFERENCES BangGia(ID)
    ON DELETE CASCADE 
    ON UPDATE CASCADE;

ALTER TABLE KhungGio
ADD CONSTRAINT FK_KhungGio_LoaiHinhTinhPhi 
    FOREIGN KEY (IDLoaiHinhTinhPhi) REFERENCES LoaiHinhTinhPhi(ID)
    ON DELETE CASCADE 
    ON UPDATE CASCADE;

ALTER TABLE TheXeThang
ADD CONSTRAINT FK_TheXeThang_KhachHang_Xe 
    FOREIGN KEY (IDKhachHang_Xe) REFERENCES KhachHang_Xe(ID)
    ON DELETE CASCADE 
    ON UPDATE CASCADE;

ALTER TABLE Voucher
ADD CONSTRAINT FK_Voucher_BaiDo 
    FOREIGN KEY (IDBaiDo) REFERENCES BaiDo(ID)
    ON DELETE CASCADE 
    ON UPDATE CASCADE;

-- 6. NGHIỆP VỤ VÀO/RA
ALTER TABLE DatCho
ADD CONSTRAINT FK_DatCho_KhachHang 
    FOREIGN KEY (IDKhachHang) REFERENCES KhachHang(ID)
    ON DELETE NO ACTION 
    ON UPDATE NO ACTION;

ALTER TABLE DatCho
ADD CONSTRAINT FK_DatCho_NhanVien 
    FOREIGN KEY (IDNhanVien) REFERENCES NhanVien(ID)
    ON DELETE SET NULL 
    ON UPDATE NO ACTION;

ALTER TABLE DatCho
ADD CONSTRAINT FK_DatCho_ChoDauXe 
    FOREIGN KEY (IDChoDau) REFERENCES ChoDauXe(ID)
    ON DELETE NO ACTION 
    ON UPDATE CASCADE;

ALTER TABLE HoaDon
ADD CONSTRAINT FK_HoaDon_Voucher 
    FOREIGN KEY (IDVoucher) REFERENCES Voucher(ID)
    ON DELETE SET NULL 
    ON UPDATE NO ACTION;

ALTER TABLE PhieuGiuXe
ADD CONSTRAINT FK_PhieuGiuXe_Xe 
    FOREIGN KEY (IDXe) REFERENCES Xe(BienSoXe)
    ON DELETE NO ACTION 
    ON UPDATE CASCADE;

ALTER TABLE PhieuGiuXe
ADD CONSTRAINT FK_PhieuGiuXe_ChoDauXe 
    FOREIGN KEY (IDChoDau) REFERENCES ChoDauXe(ID)
    ON DELETE NO ACTION 
    ON UPDATE CASCADE;

ALTER TABLE PhieuGiuXe
ADD CONSTRAINT FK_PhieuGiuXe_NhanVien 
    FOREIGN KEY (IDNhanVien) REFERENCES NhanVien(ID)
    ON DELETE SET NULL 
    ON UPDATE NO ACTION;

ALTER TABLE PhieuGiuXe
ADD CONSTRAINT FK_PhieuGiuXe_HoaDon 
    FOREIGN KEY (IDHoaDon) REFERENCES HoaDon(ID)
    ON DELETE NO ACTION 
    ON UPDATE NO ACTION;

ALTER TABLE ChiTietHoaDon
ADD CONSTRAINT FK_ChiTietHoaDon_TheXeThang 
    FOREIGN KEY (IDTheXeThang) REFERENCES TheXeThang(ID)
    ON DELETE SET NULL 
    ON UPDATE NO ACTION;

ALTER TABLE ChiTietHoaDon
ADD CONSTRAINT FK_ChiTietHoaDon_DatCho 
    FOREIGN KEY (IDDatCho) REFERENCES DatCho(ID)
    ON DELETE SET NULL 
    ON UPDATE NO ACTION;

ALTER TABLE ChiTietHoaDon
ADD CONSTRAINT FK_ChiTietHoaDon_HoaDon 
    FOREIGN KEY (IDHoaDon) REFERENCES HoaDon(ID)
    ON DELETE CASCADE 
    ON UPDATE CASCADE;

ALTER TABLE ThanhToan
ADD CONSTRAINT FK_ThanhToan_HoaDon 
    FOREIGN KEY (IDHoaDon) REFERENCES HoaDon(ID)
    ON DELETE CASCADE 
    ON UPDATE CASCADE;

-- 7. BẢNG PHỤ TRỢ
ALTER TABLE LichLamViec
ADD CONSTRAINT FK_LichLamViec_NhanVien 
    FOREIGN KEY (IDNhanVien) REFERENCES NhanVien(ID)
    ON DELETE CASCADE 
    ON UPDATE CASCADE;

ALTER TABLE LichLamViec
ADD CONSTRAINT FK_LichLamViec_CaLam 
    FOREIGN KEY (IDCaLam) REFERENCES CaLam(ID)
    ON DELETE NO ACTION 
    ON UPDATE NO ACTION;

ALTER TABLE LichLamViec
ADD CONSTRAINT FK_LichLamViec_BaiDo 
    FOREIGN KEY (IDBaiDo) REFERENCES BaiDo(ID)
    ON DELETE NO ACTION 
    ON UPDATE NO ACTION;

ALTER TABLE SuCo
ADD CONSTRAINT FK_SuCo_NhanVien 
    FOREIGN KEY (IDNhanVien) REFERENCES NhanVien(ID)
    ON DELETE SET NULL 
    ON UPDATE NO ACTION;

ALTER TABLE SuCo
ADD CONSTRAINT FK_SuCo_ThietBi 
    FOREIGN KEY (IDThietBi) REFERENCES ThietBi(ID)
    ON DELETE CASCADE 
    ON UPDATE CASCADE;

ALTER TABLE DanhGia
ADD CONSTRAINT FK_DanhGia_KhachHang 
    FOREIGN KEY (IDKhachHang) REFERENCES KhachHang(ID)
    ON DELETE NO ACTION 
    ON UPDATE NO ACTION;

ALTER TABLE DanhGia
ADD CONSTRAINT FK_DanhGia_HoaDon 
    FOREIGN KEY (IDHoaDon) REFERENCES HoaDon(ID)
    ON DELETE CASCADE 
    ON UPDATE CASCADE;
-

-- Function Tìm kiếm:Lấy danh sách chỗ trống theo khu vực
CREATE FUNCTION f_TimKiemChoTrong (@IDBaiDo INT)
RETURNS TABLE
AS
RETURN
(
    SELECT 
        bd.TenBai,
        kv.TenKhuVuc,
        cd.TenChoDau,
        cd.KichThuoc,
        cd.TrangThai
    FROM ChoDauXe cd
    JOIN KhuVuc kv ON cd.IDKhuVuc = kv.ID
    JOIN BaiDo bd ON kv.IDBaiDo = bd.ID
    WHERE 
        cd.TrangThai = N'Trống' -- Giả sử trạng thái ghi là 'Trống'
        AND (@IDBaiDo IS NULL OR bd.ID = @IDBaiDo) -- Nếu @IDBaiDo null thì lấy tất cả
);
GO

-- Function Thống kê:Tính tổng doanh thu theo tháng
CREATE FUNCTION f_TongDoanhThuThang (@Thang INT, @Nam INT)
RETURNS DECIMAL(18,2)
AS
BEGIN
    DECLARE @TongTien DECIMAL(18,2);

    SELECT @TongTien = SUM(hd.ThanhTien)
    FROM HoaDon hd
    JOIN ThanhToan tt ON hd.ID = tt.IDHoaDon
    WHERE 
        MONTH(tt.NgayThanhToan) = @Thang 
        AND YEAR(tt.NgayThanhToan) = @Nam
        AND tt.TrangThai = 1; -- Chỉ tính các giao dịch thành công

    RETURN ISNULL(@TongTien, 0);
END;
GO



-- Procedure Tìm kiếm: Tra cứu thông tin chi tiết xe
CREATE PROCEDURE sp_TimKiemThongTinXe
    @TuKhoa NVARCHAR(50) -- Có thể là Biển số hoặc Tên chủ xe
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        x.BienSoXe,
        x.TenXe,
        kh.HoTen AS ChuSoHuu,
        cd.TenChoDau,
        kv.TenKhuVuc,
        CASE 
            WHEN pgx.TgianRa IS NULL THEN N'Đang trong bãi'
            ELSE N'Đã rời bãi'
        END AS TrangThaiHienTai,
        pgx.TgianVao,
        pgx.TgianRa
    FROM Xe x
    LEFT JOIN KhachHang_Xe khx ON x.BienSoXe = khx.IDXe
    LEFT JOIN KhachHang kh ON khx.IDKhachHang = kh.ID
    LEFT JOIN PhieuGiuXe pgx ON x.BienSoXe = pgx.IDXe
    LEFT JOIN ChoDauXe cd ON pgx.IDChoDau = cd.ID
    LEFT JOIN KhuVuc kv ON cd.IDKhuVuc = kv.ID
    WHERE 
        x.BienSoXe LIKE '%' + @TuKhoa + '%' 
        OR kh.HoTen LIKE N'%' + @TuKhoa + '%'
    ORDER BY pgx.TgianVao DESC; -- Ưu tiên hiển thị lần gửi gần nhất
END;
GO


-- Procedure Thống kê: Báo cáo tổng hợp (Doanh thu & Lượt xe)
CREATE PROCEDURE sp_BaoCaoThongKeTongHop
    @NgayBatDau DATE,
    @NgayKetThuc DATE
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        CAST(tt.NgayThanhToan AS DATE) AS Ngay,
        -- Đếm số lượt xe vào (dựa trên phiếu giữ xe tạo trong ngày)
        COUNT(DISTINCT pgx.ID) AS SoLuotXeVao,
        -- Tổng doanh thu thực tế thu được
        SUM(hd.ThanhTien) AS DoanhThu,
        -- Đếm số lượng Voucher đã dùng
        COUNT(hd.IDVoucher) AS SoVoucherSuDung
    FROM ThanhToan tt
    JOIN HoaDon hd ON tt.IDHoaDon = hd.ID
    LEFT JOIN PhieuGiuXe pgx ON hd.ID = pgx.IDHoaDon
    WHERE 
        CAST(tt.NgayThanhToan AS DATE) BETWEEN @NgayBatDau AND @NgayKetThuc
        AND tt.TrangThai = 1
    GROUP BY CAST(tt.NgayThanhToan AS DATE)
    ORDER BY Ngay DESC;
END;
GO




-- Tìm chỗ trống ở bãi xe có ID = 1
SELECT * FROM f_TimKiemChoTrong(1);

-- Tính doanh thu tháng 12 năm 2025
SELECT dbo.f_TongDoanhThuThang(12, 2025) AS DoanhThuThangNay;


-- Tìm xe có biển số chứa số "999"
EXEC sp_TimKiemThongTinXe @TuKhoa = '999';

-- Xuất báo cáo từ ngày 01/12 đến 31/12
EXEC sp_BaoCaoThongKeTongHop @NgayBatDau = '2025-12-01', @NgayKetThuc = '2025-12-31';