SELECT * FROM f_TimKiemChoTrong(1);
SELECT dbo.f_TongDoanhThuThang(12, 2025) AS DoanhThu;

EXEC sp_TimKiemThongTinXe @TuKhoa = '30A';

EXEC sp_BaoCaoThongKeTongHop @NgayBatDau = '2024-01-01', @NgayKetThuc = '2026-01-01';



-- Bước 1: Thêm tài khoản
EXEC sp_ThemTaiKhoanKhachHang 'tung_nguyen_2', '123', N'Nguyễn Thanh Tùng', '0911222444', '123123555', N'Hà Nội';
select * from TaiKhoan

-- Bước 2: Thêm xe cho khách hàng vừa tạo (Giả sử ID khách hàng là 3)
EXEC sp_ThemXeKhachHang 3, '30A-888.88', 2, 'Civic', 'Honda', N'Trắng';
select * from Xe, KhachHang_Xe where xe.BienSoXe = KhachHang_Xe.IDXe and KhachHang_Xe.IDKhachHang = 3

-- Bước 3: Khách hàng đặt chỗ A-01 (ID = 1)
EXEC sp_KhachHangDatCho 3, '30A-888.88', 1, '2026-06-01 08:00', '2026-06-01 17:00';
select * from DatCho where IDKhachHang = 3

-- Kiểm tra trạng thái chỗ đậu (Sẽ tự động chuyển sang 'Đã đặt' nhờ Trigger)
SELECT TenChoDau, TrangThai FROM ChoDauXe WHERE ID = 1;

-- Xem danh sách các yêu cầu đang chờ duyệt
EXEC sp_DanhSachChoDuyet;
EXEC sp_NhanVienDuyetDatCho 2, 1, N'Hoàn thành';

-- Bước 4: Nhân viên (ID = 1) xem danh sách và duyệt
-- Kiểm tra lại: Sau khi duyệt 'Hoàn thành', chỗ đậu sẽ tự động trả về 'Trống' 
SELECT TenChoDau, TrangThai 
FROM ChoDauXe WHERE ID = 1;



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