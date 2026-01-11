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
    DECLARE @Xe TABLE (STT INT, BienSoXe VARCHAR(20));
    DECLARE @Cho TABLE (STT INT, IDChoDau VARCHAR(12));

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
           5. TÍNH TIỀN THEO BẢNG GIÁ
        =============================== */
        DECLARE @TienXe TABLE (TongTien DECIMAL(18,2));

        INSERT INTO @TienXe (TongTien)
        SELECT
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
        WHERE CAST(@TgianBatDau AS TIME)
              BETWEEN bg.ThoiGianBatDau AND bg.ThoiGianKetThuc;

        SELECT @TongTien = SUM(TongTien) FROM @TienXe;

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
        INSERT INTO HoaDon (ThanhTien, LoaiHoaDon,IDVoucher)
        VALUES (@TongTien, N'Đặt chỗ', @IDVoucher);

        DECLARE @IDHoaDon VARCHAR(20) = (SELECT MAX(IDHoaDon) FROM HoaDon);

        /* ===============================
           7. CHI TIẾT HÓA ĐƠN
        =============================== */
        INSERT INTO ChiTietHoaDon (IDHoaDonNo, TongTien)
        VALUES (@IDHoaDon, @TongTien);

        /* ===============================
           8. THANH TOÁN
        =============================== */
        INSERT INTO ThanhToan (IDHoaDonNo, PhuongThuc, TrangThai)
        VALUES (@IDHoaDon, @PhuongThuc, 1);

        DECLARE @IDThanhToan VARCHAR(12) = (SELECT MAX(IDThanhToan) FROM ThanhToan);

        /* ===============================
           9. ĐẶT CHỖ
        =============================== */
        INSERT INTO DatCho (IDKhachHangNo, IDXeNo, IDChoDauNo, TgianBatDau, TgianKetThuc, TrangThai)
        SELECT @IDKhachHang, x.BienSoXe, c.IDChoDau, @TgianBatDau, @TgianKetThuc, N'Đã thanh toán'
        FROM @Xe x
        JOIN @Cho c ON x.STT = c.STT;

        UPDATE cd
        SET TrangThai = N'chờ xác nhận'
        FROM ChoDauXe cd
        JOIN @Cho c ON cd.IDChoDauXe = c.IDChoDau;

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

