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

-- Kiểm tra SĐT Khách hàng: Phải là số và dài từ 10-15 ký tự
ALTER TABLE KhachHang
ADD CONSTRAINT CK_KhachHang_SDT 
CHECK (SDT NOT LIKE '%[^0-9]%' AND LEN(SDT) >= 10);

-- Kiểm tra SĐT Nhân viên
ALTER TABLE NhanVien
ADD CONSTRAINT CK_NhanVien_SDT 
CHECK (SDT NOT LIKE '%[^0-9]%' AND LEN(SDT) >= 10);

-- Kiểm tra SĐT Chủ bãi xe
ALTER TABLE ChuBaiXe
ADD CONSTRAINT CK_ChuBaiXe_SDT 
CHECK (SDT NOT LIKE '%[^0-9]%' AND LEN(SDT) >= 10);

-- Kiểm tra Email Nhân viên
ALTER TABLE NhanVien
ADD CONSTRAINT CK_NhanVien_Email 
CHECK (Email LIKE '%_@__%.__%');

-- Kiểm tra Email Chủ bãi xe
ALTER TABLE ChuBaiXe
ADD CONSTRAINT CK_ChuBaiXe_Email 
CHECK (Email LIKE '%_@__%.__%');

-- 1. Bảng BaiDo (TrangThai)
ALTER TABLE BaiDo
ADD CONSTRAINT CK_BaiDo_TrangThai 
CHECK (TrangThai IN (N'Hoạt động', N'Đóng cửa', N'Bảo trì', N'Tạm dừng'));

-- 2. Bảng ChoDauXe (TrangThai - Quan trọng nhất)
-- Chỉ cho phép các trạng thái logic của ô đỗ
ALTER TABLE ChoDauXe
ADD CONSTRAINT CK_ChoDauXe_TrangThai 
CHECK (TrangThai IN (N'Trống', N'Đã đặt', N'Đang đỗ', N'Bảo trì'));

-- 3. Bảng ThietBi (TrangThai)
ALTER TABLE ThietBi
ADD CONSTRAINT CK_ThietBi_TrangThai 
CHECK (TrangThai IN (N'Hoạt động', N'Hỏng', N'Bảo trì', N'Thanh lý'));

-- 4. Bảng DatCho (TrangThai)
ALTER TABLE DatCho
ADD CONSTRAINT CK_DatCho_TrangThai 
CHECK (TrangThai IN (N'Đã đặt', N'Đã hủy', N'Hoàn thành', N'Quá hạn'));

-- 5. Bảng PhieuGiuXe (TrangThai)
ALTER TABLE PhieuGiuXe
ADD CONSTRAINT CK_PhieuGiuXe_TrangThai 
CHECK (TrangThai IN (N'Đang gửi', N'Đã lấy', N'Quá hạn', N'Mất vé'));

-- 6. Bảng SuCo (TrangThaiXuLy & MucDo)
ALTER TABLE SuCo
ADD CONSTRAINT CK_SuCo_TrangThaiXuLy 
CHECK (TrangThaiXuLy IN (N'Chưa xử lý', N'Đang xử lý', N'Đã xử lý'));

ALTER TABLE SuCo
ADD CONSTRAINT CK_SuCo_MucDo 
CHECK (MucDo IN (N'Nhẹ', N'Trung bình', N'Nghiêm trọng'));

-- 7. Bảng KhachHang (LoaiKH)
ALTER TABLE KhachHang
ADD CONSTRAINT CK_KhachHang_LoaiKH 
CHECK (LoaiKH IN (N'Vãng lai', N'Thường xuyên', N'VIP'));

-- 8. Bảng ThanhToan (PhuongThuc)
ALTER TABLE ThanhToan
ADD CONSTRAINT CK_ThanhToan_PhuongThuc 
CHECK (PhuongThuc IN (N'Tiền mặt', N'Thẻ', N'QR Code', N'Chuyển khoản'));


-- Thẻ xe tháng: Mặc định là 1 (Còn hạn)
ALTER TABLE TheXeThang
ADD CONSTRAINT DF_TheXeThang_TrangThai DEFAULT 1 FOR TrangThai;

-- Voucher: Mặc định là 1 (Có thể sử dụng)
ALTER TABLE Voucher
ADD CONSTRAINT DF_Voucher_TrangThai DEFAULT 1 FOR TrangThai;

-- Lịch làm việc: Mặc định là 0 (Chưa duyệt/Chờ duyệt) hoặc 1 tuỳ logic
ALTER TABLE LichLamViec
ADD CONSTRAINT DF_LichLamViec_TrangThai DEFAULT 0 FOR TrangThai;

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

--cập nhật trạng thái đỗ xe khi đặt vé
go
create trigger capnhatrangthaidokhiVao
on datcho
after insert
as
begin
	update ChoDauXe
	set TrangThai = N'Đã đặt'
	from ChoDauXe c
	join inserted i on c.ID = i.IDChoDau
end

--cập nhật trạng thái đỗ xe khi khách ra
go
CREATE TRIGGER trg_CapNhatTrangThai_KhiRa
ON PhieuGiuXe
AFTER UPDATE
AS
BEGIN
    IF UPDATE(TgianRa)
    BEGIN
        UPDATE ChoDauXe
        SET TrangThai = N'Trống'
        FROM ChoDauXe c
        JOIN Inserted i ON c.ID = i.IDChoDau
        WHERE i.TgianRa IS NOT NULL;
    END
END;

--cập nhất trạng thái chỗ sau khi đặt thành công hoặc hủy
go
CREATE TRIGGER trg_GiaiPhongCho_KhiHuyDat
ON DatCho
AFTER UPDATE
AS
BEGIN
	update ChoDauXe
	set TrangThai = N'Trống'
	from ChoDauXe c join inserted i on c.ID = i.IDChoDau
	where i.TrangThai IN (N'Đã hủy', N'Hoàn thành', N'Quá hạn')
		and c.TrangThai = N'Đã đặt'
end

--: Tự động tính tổng tiền hóa đơn khi thay đổi Chi tiết
go
CREATE TRIGGER trg_TinhTongTien_HoaDon
ON ChiTietHoaDon
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    DECLARE @AffectedIDs TABLE (IDHoaDon INT);

    INSERT INTO @AffectedIDs
    SELECT IDHoaDon FROM Inserted
    UNION
    SELECT IDHoaDon FROM Deleted;

    UPDATE HoaDon
    SET ThanhTien = (
        SELECT ISNULL(SUM(TongTien), 0)
        FROM ChiTietHoaDon
        WHERE ChiTietHoaDon.IDHoaDon = HoaDon.ID
    )
    WHERE ID IN (SELECT IDHoaDon FROM @AffectedIDs);
END;

-- Ngăn chặn trùng lịch đặt chỗ
go
CREATE TRIGGER trg_CheckTrungLich_DatCho
ON DatCho
AFTER INSERT, UPDATE
AS
BEGIN
    IF EXISTS (
        SELECT 1
        FROM DatCho d
        JOIN Inserted i ON d.IDChoDau = i.IDChoDau
        WHERE d.ID <> i.ID
          AND d.TrangThai NOT IN (N'Đã hủy')
          AND (d.TgianBatDau < i.TgianKetThuc AND d.TgianKetThuc > i.TgianBatDau)
    )
    BEGIN
        ROLLBACK TRANSACTION;
        RAISERROR (N'Lỗi: Chỗ đậu xe này đã có người đặt trong khung giờ này!', 16, 1);
        RETURN;
    END
END;

--kiểm tra hóa đơn dùng voucher
go
create trigger trg_XuLyVoucher_HoaDon
on hoadon
after insert
as
begin
	if exists (select 1 from inserted where IDVoucher is not null)
	begin
		if exists (
			select 1
			from Voucher v join inserted i on v.ID = i.IDVoucher
			where v.SoLuong > 0 or v.HanSuDung < GETDATE()
		)
		BEGIN
            ROLLBACK TRANSACTION;
            RAISERROR (N'Lỗi: Voucher đã hết hạn hoặc hết số lượng!', 16, 1);
            RETURN;
        END

		update Voucher
		set SoLuong = SoLuong - 1
		from Voucher v join inserted i on v.ID = i.IDVoucher
	end
end;



-- TRIGGER QUẢN LÝ THẺ XE THÁNG (Đăng ký, Gia hạn, Hủy)
CREATE TRIGGER trg_KiemTraTheXeThang
ON TheXeThang
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @NgayDangKy DATE, @NgayHetHan DATE, @TrangThai BIT;
    
    -- Lấy dữ liệu từ dòng vừa được thêm hoặc sửa
    SELECT @NgayDangKy = NgayDangKy, 
           @NgayHetHan = NgayHetHan, 
           @TrangThai = TrangThai
    FROM inserted;

    -- 1. LOGIC ĐĂNG KÝ & GIA HẠN: Kiểm tra ngày hợp lệ
    IF @NgayHetHan IS NOT NULL AND @NgayDangKy IS NOT NULL
    BEGIN
        IF @NgayHetHan <= @NgayDangKy
        BEGIN
            RAISERROR(N'Lỗi: Ngày hết hạn phải lớn hơn ngày đăng ký.', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END
    END

    -- 2. LOGIC HỦY THẺ: Nếu TrangThai chuyển sang 0 (False), không cần xóa record, chỉ cần đảm bảo logic nghiệp vụ
    -- (Phần này SQL tự lưu update, trigger chỉ dùng để chặn nếu có rule đặc biệt, ví dụ: Không cho hủy khi còn nợ tiền)
    
    -- 3. LOGIC TỰ ĐỘNG KÍCH HOẠT KHI GIA HẠN
    -- Nếu người dùng update Ngày hết hạn mới > Ngày hiện tại, tự động set TrangThai = 1 (Active)
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



-- TRIGGER XỬ LÝ XE VÀO / RA (Tự động cập nhật Chỗ Đậu)
CREATE TRIGGER trg_CapNhatTrangThaiChoDau
ON PhieuGiuXe
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- TRƯỜNG HỢP 1: XE VÀO (INSERT)
    -- Khi tạo phiếu giữ xe mới, cập nhật trạng thái chỗ đậu thành 'Đang đỗ'
    IF EXISTS (SELECT * FROM inserted) AND NOT EXISTS (SELECT * FROM deleted)
    BEGIN
        UPDATE ChoDauXe
        SET TrangThai = N'Đang đỗ'
        FROM ChoDauXe c
        JOIN inserted i ON c.ID = i.IDChoDau;
    END

    -- TRƯỜNG HỢP 2: XE RA (UPDATE)
    -- Khi cập nhật thời gian ra (TgianRa khác NULL), cập nhật trạng thái chỗ đậu thành 'Trống'
    IF UPDATE(TgianRa)
    BEGIN
        UPDATE ChoDauXe
        SET TrangThai = N'Trống'
        FROM ChoDauXe c
        JOIN inserted i ON c.ID = i.IDChoDau
        WHERE i.TgianRa IS NOT NULL; -- Chỉ khi xe thực sự đã ra
    END
    
    -- TRƯỜNG HỢP 3: ĐỔI CHỖ ĐẬU (UPDATE IDChoDau)
    -- Nếu nhân viên đổi chỗ xe sang vị trí khác khi xe đang gửi
    IF UPDATE(IDChoDau)
    BEGIN
        -- Trả lại trạng thái 'Trống' cho chỗ cũ
        UPDATE ChoDauXe
        SET TrangThai = N'Trống'
        FROM ChoDauXe c
        JOIN deleted d ON c.ID = d.IDChoDau;

        -- Set trạng thái 'Đang đỗ' cho chỗ mới
        UPDATE ChoDauXe
        SET TrangThai = N'Đang đỗ'
        FROM ChoDauXe c
        JOIN inserted i ON c.ID = i.IDChoDau;
    END
END;
GO