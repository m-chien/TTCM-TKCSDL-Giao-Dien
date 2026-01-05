-- ====================Function========================
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
            VALUES (@IDTK, @HoTen, @SDT, @CCCD, @DiaChi, N'Thường xuyên');
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
    IF NOT EXISTS (SELECT 1 FROM KhachHang_Xe WHERE IDKhachHang = @IDKhachHang AND IDXe = @BienSoXe)
    BEGIN
        RAISERROR(N'Lỗi: Xe này chưa được đăng ký dưới tên khách hàng này!', 16, 1);
        RETURN;
    END

    -- 3. KIỂM TRA TRẠNG THÁI CẤU HÌNH CỦA CHỖ ĐỖ
    -- Nếu chỗ đang bảo trì hoặc tạm dừng thì không cho đặt
    IF EXISTS (SELECT 1 FROM ChoDauXe WHERE ID = @IDChoDau AND TrangThai IN (N'Bảo trì', N'Tạm dừng', N'Đóng cửa'))
    BEGIN
        RAISERROR(N'Lỗi: Vị trí đỗ xe này đang bảo trì hoặc tạm dừng hoạt động!', 16, 1);
        RETURN;
    END

    -- 4. KIỂM TRA TRÙNG LỊCH ĐẶT (Booking Overlap)
    IF EXISTS (
        SELECT 1 
        FROM DatCho 
        WHERE IDChoDau = @IDChoDau 
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
        WHERE IDChoDau = @IDChoDau 
          AND TgianRa IS NULL -- Xe chưa ra
          AND @TgianBatDau <= GETDATE() -- Khách muốn đặt ngay lúc này
    )
    BEGIN
        RAISERROR(N'Lỗi: Vị trí này hiện đang có xe đỗ, vui lòng chọn chỗ khác hoặc khung giờ khác!', 16, 1);
        RETURN;
    END

    -- 6. THỰC HIỆN ĐẶT CHỖ
    BEGIN TRY
        INSERT INTO DatCho (IDKhachHang, IDXe, IDChoDau, TgianBatDau, TgianKetThuc, TrangThai)
        VALUES (@IDKhachHang, @BienSoXe, @IDChoDau, @TgianBatDau, @TgianKetThuc, N'Đang chờ duyệt');
        
        PRINT N'Đặt chỗ thành công cho xe ' + @BienSoXe + N' tại vị trí ID ' + CAST(@IDChoDau AS NVARCHAR(10));
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
    @IDDatCho INT,
    @IDKhachHang INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Chỉ cho hủy khi là chủ đơn và chưa bắt đầu gửi xe
    IF NOT EXISTS (
        SELECT 1
        FROM DatCho
        WHERE ID = @IDDatCho
          AND IDKhachHang = @IDKhachHang
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
    WHERE ID = @IDDatCho;

    PRINT N'Khách hàng đã hủy đặt chỗ thành công.';
END;
GO


-- Nhân viên duyệt
IF OBJECT_ID('sp_NhanVienDuyetDatCho') IS NOT NULL DROP PROCEDURE sp_NhanVienDuyetDatCho;
GO
CREATE PROCEDURE sp_NhanVienDuyetDatCho
    @IDDatCho INT,
    @IDNhanVien INT,
    @TrangThaiMoi NVARCHAR(50) -- N'Đã đặt' (Duyệt) hoặc N'Đã hủy' (Từ chối)
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @IDChoDau INT;
    DECLARE @TrangThaiHienTai NVARCHAR(50);

    -- Lấy thông tin chỗ đậu từ đơn đặt hàng
    SELECT @IDChoDau = IDChoDau, @TrangThaiHienTai = TrangThai
    FROM DatCho 
    WHERE ID = @IDDatCho;

    -- 1. Kiểm tra đơn này có tồn tại không
    IF @IDChoDau IS NULL
    BEGIN
        RAISERROR(N'Lỗi: Đơn đặt chỗ không tồn tại.', 16, 1);
        RETURN;
    END

    -- 2. Kiểm tra trạng thái đơn (Chỉ được duyệt đơn đang chờ)
    -- Giả sử quy trình của bạn là: Khách đặt -> "Đang chờ duyệt" -> NV Duyệt -> "Đã đặt"
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
                IF EXISTS (SELECT 1 FROM ChoDauXe WHERE ID = @IDChoDau AND TrangThai <> N'Trống')
                BEGIN
                    RAISERROR(N'Lỗi: Không thể duyệt. Chỗ đậu xe này hiện không còn trống (Đang đỗ/Bảo trì).', 16, 1);
                    ROLLBACK TRANSACTION;
                    RETURN;
                END
                -- Cập nhật trạng thái Chỗ đậu -> "Đã đặt"
                UPDATE ChoDauXe SET TrangThai = N'Đã đặt' WHERE ID = @IDChoDau;
            END

            -- TRƯỜNG HỢP 2: TỪ CHỐI/HỦY ĐƠN
            ELSE IF @TrangThaiMoi = N'Đã hủy'
            BEGIN
                UPDATE ChoDauXe SET TrangThai = N'Trống' WHERE ID = @IDChoDau AND TrangThai = N'Đã đặt';
            END

            -- 3. Cập nhật trạng thái Đơn đặt chỗ
            UPDATE DatCho
            SET TrangThai = @TrangThaiMoi,
                IDNhanVien = @IDNhanVien
            WHERE ID = @IDDatCho;

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

-- Thống kê danh sách đặt chỗ đang chờ duyệt (Trạng thái 'Đang chờ duyệt')
IF OBJECT_ID('sp_DanhSachChoDuyet') IS NOT NULL DROP PROCEDURE sp_DanhSachChoDuyet;
GO
CREATE PROCEDURE sp_DanhSachChoDuyet
AS
BEGIN
    SELECT dc.ID AS IDDatCho, kh.HoTen, kh.SDT, cd.TenChoDau, dc.TgianBatDau, dc.TgianKetThuc
    FROM DatCho dc
    JOIN KhachHang kh ON dc.IDKhachHang = kh.ID
    JOIN ChoDauXe cd ON dc.IDChoDau = cd.ID
    WHERE dc.TrangThai = N'Đang chờ duyệt'
    ORDER BY dc.TgianBatDau ASC;
END;
GO




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

GO
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

--đăng ký thẻ xe tháng
IF OBJECT_ID('sp_DangKyTheXeThang') IS NOT NULL DROP PROCEDURE sp_DangKyTheXeThang;
GO
Create PROCEDURE sp_DangKyTheXeThang
    @IDKhachHang INT,
    @IDXe VARCHAR(20),
    @TenTheXe NVARCHAR(255),
    @SoThang INT,
    @GiaThang MONEY = 300000
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRAN;

        -- 1. Kiểm tra trùng thẻ còn hiệu lực
        IF EXISTS (
            SELECT 1
            FROM TheXeThang
            WHERE IDKhachHang = @IDKhachHang
              AND IDXe = @IDXe
              AND TrangThai = 1
              AND NgayHetHan >= CAST(GETDATE() AS DATE)
        )
        BEGIN
            RAISERROR(
                N'Xe này đã có thẻ tháng còn hiệu lực. Vui lòng gia hạn.',
                16, 1
            );
            ROLLBACK;
            RETURN;
        END

        DECLARE 
            @NgayDangKy DATE = CAST(GETDATE() AS DATE),
            @NgayHetHan DATE,
            @TongTien MONEY,
            @IDHoaDon INT,
            @IDTheXeThang INT;

        SET @NgayHetHan = DATEADD(MONTH, @SoThang, @NgayDangKy);
        SET @TongTien = @SoThang * @GiaThang;

        -- 2. Tạo thẻ xe tháng
        INSERT INTO TheXeThang
        (IDKhachHang, IDXe, TenTheXe, NgayDangKy, NgayHetHan, TrangThai)
        VALUES
        (@IDKhachHang, @IDXe, @TenTheXe, @NgayDangKy, @NgayHetHan, 1);

        SET @IDTheXeThang = SCOPE_IDENTITY();

        -- 3. Tạo hóa đơn
        INSERT INTO HoaDon (ThanhTien, NgayTao, LoaiHoaDon)
        VALUES (@TongTien, GETDATE(), N'Đăng ký thẻ xe tháng');

        SET @IDHoaDon = SCOPE_IDENTITY();

        -- 4. Chi tiết hóa đơn
        INSERT INTO ChiTietHoaDon (IDHoaDon, IDTheXeThang, TongTien)
        VALUES (@IDHoaDon, @IDTheXeThang, @TongTien);

        -- 5. Thanh toán
        INSERT INTO ThanhToan
        (IDHoaDon, PhuongThuc, TrangThai, NgayThanhToan)
        VALUES
        (@IDHoaDon, N'Tiền mặt', 1, GETDATE());

        COMMIT;
        PRINT N'Đăng ký thẻ xe tháng thành công';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;
        THROW;
    END CATCH
END;
GO

--gia hạn thẻ xe tháng
IF OBJECT_ID('sp_GiaHanTheXeThang') IS NOT NULL DROP PROCEDURE sp_GiaHanTheXeThang;
GO
CREATE PROCEDURE sp_GiaHanTheXeThang
    @IDTheXeThang INT,
    @SoThang INT,
    @GiaThang MONEY = 300000
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRAN;

    BEGIN TRY
        DECLARE @TongTien MONEY = @SoThang * @GiaThang;
        DECLARE @IDHoaDon INT;

        -- 1. Gia hạn thẻ
        UPDATE TheXeThang
        SET NgayHetHan = DATEADD(MONTH, @SoThang, NgayHetHan),
            TrangThai = 1
        WHERE ID = @IDTheXeThang;

        -- 2. Tạo hóa đơn
        INSERT INTO HoaDon (ThanhTien, NgayTao, LoaiHoaDon)
        VALUES (@TongTien, GETDATE(), N'Gia hạn thẻ tháng');

        SET @IDHoaDon = SCOPE_IDENTITY();

        -- 3. Chi tiết hóa đơn
        INSERT INTO ChiTietHoaDon (IDHoaDon, IDTheXeThang, TongTien)
        VALUES (@IDHoaDon, @IDTheXeThang, @TongTien);

        -- 4. Thanh toán
        INSERT INTO ThanhToan (IDHoaDon, PhuongThuc, TrangThai, NgayThanhToan)
        VALUES (@IDHoaDon, N'Tiền mặt', 1, GETDATE());

        COMMIT;
        PRINT N'Gia hạn thẻ xe tháng thành công';
    END TRY
    BEGIN CATCH
        ROLLBACK;
        THROW;
    END CATCH
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
    JOIN inserted i ON c.ID = i.IDChoDau
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
    JOIN inserted i ON c.ID = i.IDChoDau
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


