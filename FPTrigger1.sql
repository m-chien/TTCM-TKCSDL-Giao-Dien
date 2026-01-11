
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

