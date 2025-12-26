 
CREATE DATABASE ParkingLot
-- 1. BẢNG DANH MỤC & CẤU HÌNH CƠ BẢN
CREATE TABLE VaiTro (
    ID INT PRIMARY KEY IDENTITY(1,1),
    TenVaiTro NVARCHAR(50) NOT NULL
);

CREATE TABLE LoaiXe (
    ID INT PRIMARY KEY IDENTITY(1,1),
    TenLoaiXe NVARCHAR(50) NOT NULL
);

CREATE TABLE LoaiHinhTinhPhi (
    ID INT PRIMARY KEY IDENTITY(1,1),
    TenLoaiHinh NVARCHAR(100),
    KhungGioBatDau TIME,
    KhungGioKetThuc TIME
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
    IDLoaiHinhTinhPhi INT FOREIGN KEY REFERENCES LoaiHinhTinhPhi(ID),
    IDBaiDo INT FOREIGN KEY REFERENCES BaiDo(ID),
    IDLoaiXe INT FOREIGN KEY REFERENCES LoaiXe(ID),
    TenBangGia NVARCHAR(100),
    GiaCoDinh DECIMAL(18,2), -- Giá cơ bản
    DonViThoiGian INT -- Tính theo giờ/ngày/tháng
);

CREATE TABLE TheXeThang (
    ID INT PRIMARY KEY IDENTITY(1,1),
    IDKhachHang_Xe INT FOREIGN KEY REFERENCES KhachHang_Xe(ID),
    TenTheXe NVARCHAR(100),
    NgayDangKy DATE,
    NgayHetHan DATE,
    TrangThai BIT,
    GiaVe DECIMAL(18,2)
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


go
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