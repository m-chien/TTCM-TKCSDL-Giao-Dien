IF OBJECT_ID('fn_NextID_KhachHang') IS NOT NULL
    DROP FUNCTION fn_NextID_KhachHang;
GO

CREATE FUNCTION fn_NextID_KhachHang
(
    @LoaiKH NVARCHAR(50) -- VIP | Bình thường | Thường xuyên | Vãng lai
)
RETURNS VARCHAR(12)
AS
BEGIN
    DECLARE @Next INT;
    DECLARE @Suffix VARCHAR(2);

    -- Map LoaiKH -> suffix
    SET @Suffix = CASE @LoaiKH
        WHEN N'VIP' THEN 'VI'
        WHEN N'Thường xuyên' THEN 'TT'
        WHEN N'Vãng lai' THEN 'VL'
        ELSE 'BT'
    END;

    -- Lấy số tăng toàn bảng
    SELECT @Next =
        ISNULL(MAX(CAST(SUBSTRING(IDKhachHang, 3, 5) AS INT)), 0) + 1
    FROM KhachHang;

    RETURN
        'KH'
        + RIGHT('00000' + CAST(@Next AS VARCHAR), 5)
        + '_' + @Suffix;
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
