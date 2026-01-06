SELECT * FROM f_TimKiemChoTrong(1);
SELECT dbo.f_TongDoanhThuThang(12, 2025) AS DoanhThu;

EXEC sp_TimKiemThongTinXe @TuKhoa = '30A';

EXEC sp_BaoCaoThongKeTongHop @NgayBatDau = '2024-01-01', @NgayKetThuc = '2026-01-01';



-- Bước 1: Thêm tài khoản
EXEC sp_ThemTaiKhoanKhachHang 'tung_nguyen_2', '123', N'Nguyễn Thanh Tùng', '0911222444', '123123555', N'Hà Nội';
select * from TaiKhoan
select * from KhachHang

-- Bước 2: Thêm xe cho khách hàng vừa tạo (Giả sử ID khách hàng là 3)
EXEC sp_ThemXeKhachHang 3, '30A-888.88', 2, 'Civic', 'Honda', N'Trắng';
select * from Xe, KhachHang_Xe where xe.BienSoXe = KhachHang_Xe.IDXe and KhachHang_Xe.IDKhachHang = 3

-- Bước 3: Khách hàng đặt chỗ A-03 (ID = 3)
EXEC sp_KhachHangDatCho 3, '30A-888.88', 3, '2026-11-01 08:00', '2026-11-01 17:00';

-- Kiểm tra: Chỗ đậu vẫn phải là 'Trống' (chưa bị khóa vì chưa duyệt)
SELECT TenChoDau, TrangThai FROM ChoDauXe 

-- Bước 4: Nhân viên duyệt
EXEC sp_DanhSachChoDuyet;

-- Duyệt đơn (Chuyển sang 'Đã đặt' -> Khóa chỗ)
DECLARE @IDDonDat INT = (SELECT MAX(ID) FROM DatCho WHERE IDKhachHang = 3);
EXEC sp_NhanVienDuyetDatCho @IDDonDat, 1, N'Đã đặt';

-- Kiểm tra lại: Bây giờ chỗ đậu phải chuyển sang 'Đã đặt'
SELECT TenChoDau, TrangThai FROM ChoDauXe WHERE ID = 3;



-- 1. Cho xe vào bãi
EXEC sp_XeVaoBai 3, '30A-888.88', 3, 1;
--Kiểm tra phiếu giữ xe vừa tạo
SELECT * FROM PhieuGiuXe WHERE IDXe = '30A-888.88' AND TgianRa IS NULL;
-- 2. Giả lập gửi 3 tiếng
UPDATE PhieuGiuXe 
SET TgianVao = DATEADD(HOUR, -3, GETDATE()) 
WHERE IDXe = '30A-888.88' AND TgianRa IS NULL;

-- 3. Cho xe ra bãi
-- Lấy ID phiếu mới nhất
DECLARE @IDPhieu INT = (SELECT MAX(ID) FROM PhieuGiuXe WHERE IDXe = '30A-888.88');
EXEC sp_XeRaBai @IDPhieu, 1;

-- 4. Xem kết quả (Chắc chắn sẽ có tiền)
SELECT * FROM HoaDon WHERE ID = (SELECT IDHoaDon FROM PhieuGiuXe WHERE ID = @IDPhieu);

-- 5. Kiểm tra trạng thái chỗ đậu (Phải trở về 'Trống')
SELECT TenChoDau, TrangThai FROM ChoDauXe WHERE ID = 3;

--gia hạn thẻ xe tháng
EXEC sp_GiaHanTheXeThang
    @IDTheXeThang = 3,
    @SoThang = 2,
    @GiaThang = 300000;

-- đăng ký thẻ xe tháng
EXEC sp_DangKyTheXeThang
    @IDKhachHang = 3,
    @IDXe = '30A-888.88',
	@TenTheXe = N'Thẻ xe tháng',
    @SoThang = 1;

select * from TheXeThang
select * from HoaDon
select * from ChiTietHoaDon
select * from ThanhToan
select * from DatCho where IDChoDau = 3
select * from PhieuGiuXe

EXEC sp_KhachHangHuyDatCho 
    @IDDatCho = 2,
    @IDKhachHang = 3;
