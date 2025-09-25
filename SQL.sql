/* ============================================================
   0) Xóa database cũ nếu tồn tại
   ============================================================ */
USE master;
GO
IF DB_ID(N'QuanLyBanHang') IS NOT NULL
BEGIN
    ALTER DATABASE QuanLyBanHang SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE QuanLyBanHang;
END
GO

/* ============================================================
   1) Tạo Database
   ============================================================ */
CREATE DATABASE QuanLyBanHang;
GO
USE QuanLyBanHang;
GO

/* ============================================================
   2) Bảng Sản phẩm
   ============================================================ */
CREATE TABLE dbo.SanPham
(
    MaSP   VARCHAR(20)    NOT NULL PRIMARY KEY,
    TenSP  NVARCHAR(200)  NOT NULL,
    DonGia DECIMAL(18,2)  NOT NULL CHECK (DonGia >= 0)
);
GO

/* ============================================================
   3) Bảng Lịch sử bấm
   ============================================================ */
CREATE TABLE dbo.LichSuBam
(
    ID        BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_LichSuBam PRIMARY KEY,
    MaSP      VARCHAR(20) NOT NULL,
    TenSP     NVARCHAR(200) NULL,
    SoLuong   INT NOT NULL CHECK (SoLuong > 0),
    ThanhTien DECIMAL(18,2) NULL,
    NgayBam   DATE NOT NULL DEFAULT (GETDATE()),
    CONSTRAINT FK_LichSuBam_SanPham FOREIGN KEY (MaSP) REFERENCES dbo.SanPham(MaSP)
);
GO

/* ============================================================
   4) Trigger: tự động điền TenSP và ThanhTien
   ============================================================ */
CREATE TRIGGER dbo.trg_LichSuBam_Audit
ON dbo.LichSuBam
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE L
    SET 
        L.TenSP     = ISNULL(L.TenSP, S.TenSP),
        L.ThanhTien = S.DonGia * L.SoLuong
    FROM dbo.LichSuBam AS L
    JOIN inserted AS I    ON I.ID = L.ID
    JOIN dbo.SanPham AS S ON S.MaSP = L.MaSP;
END;
GO

/* ============================================================
   5) Bảng DoanhThu (tổng từ trước tới giờ theo sản phẩm)
   ============================================================ */
CREATE TABLE dbo.DoanhThu
(
    MaSP         VARCHAR(20)  NOT NULL PRIMARY KEY,
    TenSP        NVARCHAR(200) NOT NULL,
    SoLuong      INT NOT NULL DEFAULT(0),
    TongDoanhThu DECIMAL(18,2) NOT NULL DEFAULT(0),
    CONSTRAINT FK_DoanhThu_SanPham FOREIGN KEY (MaSP) REFERENCES dbo.SanPham(MaSP)
);
GO

/* ============================================================
   6) Stored Procedure: cập nhật bảng DoanhThu
   ============================================================ */
CREATE PROCEDURE dbo.sp_CapNhat_DoanhThu
AS
BEGIN
    SET NOCOUNT ON;

    MERGE dbo.DoanhThu AS T
    USING
    (
        SELECT L.MaSP,
               MAX(ISNULL(L.TenSP, S.TenSP)) AS TenSP,
               SUM(L.SoLuong) AS SoLuong,
               SUM(ISNULL(L.ThanhTien,0)) AS TongDoanhThu
        FROM dbo.LichSuBam L
        JOIN dbo.SanPham S ON S.MaSP = L.MaSP
        GROUP BY L.MaSP
    ) AS X
    ON T.MaSP = X.MaSP
    WHEN MATCHED THEN
        UPDATE SET T.TenSP = X.TenSP,
                   T.SoLuong = X.SoLuong,
                   T.TongDoanhThu = X.TongDoanhThu
    WHEN NOT MATCHED THEN
        INSERT (MaSP, TenSP, SoLuong, TongDoanhThu)
        VALUES (X.MaSP, X.TenSP, X.SoLuong, X.TongDoanhThu);
END;
GO

/* ============================================================
   7) Bảng Tổng doanh thu theo tháng (12 tháng gần nhất)
   ============================================================ */
CREATE TABLE dbo.TongDoanhThuTungThang
(
    Thang        CHAR(7) NOT NULL PRIMARY KEY,   -- yyyy-MM
    TongDoanhThu DECIMAL(18,2) NOT NULL DEFAULT(0)
);
GO

/* ============================================================
   8) Stored Procedure: cập nhật bảng TongDoanhThuTungThang
   ============================================================ */
CREATE PROCEDURE dbo.sp_CapNhat_TongDoanhThuTungThang
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ThangHienTai DATE = DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1);

    MERGE dbo.TongDoanhThuTungThang AS T
    USING
    (
        SELECT 
            FORMAT(NgayBam,'yyyy-MM') AS Thang,
            SUM(ThanhTien) AS TongDoanhThu
        FROM dbo.LichSuBam
        WHERE NgayBam >= DATEADD(MONTH, -12, @ThangHienTai)
          AND NgayBam < @ThangHienTai
        GROUP BY FORMAT(NgayBam,'yyyy-MM')
    ) AS X
    ON T.Thang = X.Thang
    WHEN MATCHED THEN
        UPDATE SET T.TongDoanhThu = X.TongDoanhThu
    WHEN NOT MATCHED THEN
        INSERT (Thang, TongDoanhThu)
        VALUES (X.Thang, X.TongDoanhThu);
END;
GO

/* ============================================================
   9) Dữ liệu mẫu
   ============================================================ */
INSERT INTO dbo.SanPham (MaSP, TenSP, DonGia)
VALUES 
('SP01', N'Chuột không dây', 150000),
('SP02', N'Bàn phím cơ',     850000),
('SP03', N'Màn hình 24"',    3200000),
('SP04', N'Tai nghe bluetooth', 550000),
('SP05', N'Ổ cứng SSD 1TB',       1900000),
('SP06', N'Loa Bluetooth',         690000),
('SP07', N'USB 64GB',              150000),
('SP08', N'Webcam 2K',            1150000),
('SP09', N'Router Wi-Fi 6',       1290000),
('SP10', N'Hub Type-C 6-in-1',     590000),
('SP11', N'Bàn di chuột',          120000),
('SP12', N'Màn hình 27"',         4200000),
('SP13', N'Tai nghe gaming',       990000),
('SP14', N'Ghế công thái học',    3500000),
('SP15', N'Chuột gaming',          450000),
('SP16', N'Bàn phím văn phòng',    390000),
('SP17', N'Ổ cứng HDD 1TB',       1200000),
('SP18', N'Ổ cứng HDD 2TB',       1800000),
('SP19', N'Tai nghe in-ear',       350000),
('SP20', N'Loa soundbar',         2100000),
('SP21', N'Laptop stand',          300000),
('SP22', N'Pad sạc không dây',     350000),
('SP23', N'Card mạng Wi-Fi',       250000),
('SP24', N'Dây HDMI 2.1',          180000),
('SP25', N'Micro USB',             200000),
('SP26', N'Nguồn máy tính 500W',  1200000),
('SP27', N'Case máy tính',        1500000),
('SP28', N'Quạt tản nhiệt',        160000),
('SP29', N'Keo tản nhiệt',          90000),
('SP30', N'Bộ chia USB 4 cổng',    220000),
('SP31', N'Ổ cắm thông minh',      450000),
('SP32', N'Camera an ninh',       1490000),
('SP33', N'Bộ phát Wi-Fi Mesh',   2700000),
('SP34', N'Pin sạc dự phòng',      650000),
('SP35', N'Cáp USB-C to C',        120000),
('SP36', N'Đầu đọc thẻ nhớ',       190000),
('SP37', N'Thẻ nhớ 128GB',         320000),
('SP38', N'Máy in phun',          2300000),
('SP39', N'Mực in',                250000),
('SP40', N'Giá đỡ màn hình',       400000);


/* ============================================================
   Thêm dữ liệu vào dbo.LichSuBam dựa trên danh sách SanPham
   ============================================================ */
INSERT INTO dbo.LichSuBam (MaSP, SoLuong, NgayBam) VALUES
('SP01',  3, DATEADD(MONTH, -11, GETDATE())),
('SP02',  2, DATEADD(MONTH, -10, GETDATE())),
('SP03',  1, DATEADD(MONTH, -9,  GETDATE())),
('SP04',  4, DATEADD(MONTH, -8,  GETDATE())),
('SP05',  2, DATEADD(MONTH, -7,  GETDATE())),
('SP06',  5, DATEADD(MONTH, -6,  GETDATE())),
('SP07', 10, DATEADD(MONTH, -5,  GETDATE())),
('SP08',  3, DATEADD(MONTH, -4,  GETDATE())),
('SP09',  4, DATEADD(MONTH, -3,  GETDATE())),
('SP10',  6, DATEADD(MONTH, -2,  GETDATE())),
('SP11',  8, DATEADD(MONTH, -1,  GETDATE())),
('SP12',  1, DATEADD(DAY,   -25, GETDATE())),
('SP13',  7, DATEADD(DAY,   -50, GETDATE())),
('SP14',  2, DATEADD(DAY,   -75, GETDATE())),
('SP15',  9, DATEADD(DAY,  -100, GETDATE())),
('SP16',  3, DATEADD(DAY,  -120, GETDATE())),
('SP17',  6, DATEADD(DAY,  -140, GETDATE())),
('SP18',  5, DATEADD(DAY,  -160, GETDATE())),
('SP19',  4, DATEADD(DAY,  -180, GETDATE())),
('SP20',  2, DATEADD(DAY,  -200, GETDATE())),
('SP21',  7, DATEADD(DAY,  -220, GETDATE())),
('SP22',  6, DATEADD(DAY,  -240, GETDATE())),
('SP23',  3, DATEADD(DAY,  -260, GETDATE())),
('SP24',  8, DATEADD(DAY,  -280, GETDATE())),
('SP25',  5, DATEADD(DAY,  -300, GETDATE())),
('SP26',  4, DATEADD(DAY,  -320, GETDATE())),
('SP27',  2, DATEADD(DAY,  -340, GETDATE())),
('SP28', 10, DATEADD(DAY,  -360, GETDATE())),
('SP29', 12, DATEADD(DAY,  -15,  GETDATE())),
('SP30',  7, DATEADD(DAY,  -45,  GETDATE())),
('SP31',  6, DATEADD(DAY,  -75,  GETDATE())),
('SP32',  3, DATEADD(DAY, -105,  GETDATE())),
('SP33',  2, DATEADD(DAY, -135,  GETDATE())),
('SP34',  9, DATEADD(DAY, -165,  GETDATE())),
('SP35', 11, DATEADD(DAY, -195,  GETDATE())),
('SP36',  4, DATEADD(DAY, -225,  GETDATE())),
('SP37',  5, DATEADD(DAY, -255,  GETDATE())),
('SP38',  2, DATEADD(DAY, -285,  GETDATE())),
('SP39', 15, DATEADD(DAY, -315,  GETDATE())),
('SP40',  6, DATEADD(DAY, -345,  GETDATE()));

/* ============================================================
   10) Chạy thử
   ============================================================ */
EXEC dbo.sp_CapNhat_DoanhThu;
EXEC dbo.sp_CapNhat_TongDoanhThuTungThang;

SELECT * FROM dbo.SanPham ORDER BY MaSP;
SELECT * FROM dbo.DoanhThu ORDER BY MaSP;
SELECT * FROM dbo.TongDoanhThuTungThang ORDER BY Thang;
