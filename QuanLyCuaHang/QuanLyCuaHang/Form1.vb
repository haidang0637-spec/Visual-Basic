Imports System.Data
Imports Microsoft.Data.SqlClient
Imports System.Windows.Forms.DataVisualization.Charting

Public Class Form1

    ' ====== KẾT NỐI SQL ======
    Private ReadOnly connStr As String =
        "Data Source=localhost;Initial Catalog=QuanLyBanHang;Integrated Security=True;TrustServerCertificate=True"

    ' ====== BINDINGSOURCE để lọc grid SanPham ======
    Private bsSanPham As New BindingSource()

    ' ================== FORM LOAD ==================
    Private Sub Form1_Load(sender As Object, e As EventArgs) Handles MyBase.Load
        ' Map DataPropertyName cho Guna2DataGridView1 (Sản phẩm)
        Guna2DataGridView1.AutoGenerateColumns = False
        Guna2DataGridView1.Columns("maSp").DataPropertyName = "MaSP"
        Guna2DataGridView1.Columns("tenSP").DataPropertyName = "TenSP"
        Guna2DataGridView1.Columns("donGia").DataPropertyName = "DonGia"
        LoadSanPham1() ' => gán bsSanPham vào Guna2DataGridView1

        ' Map DataPropertyName cho Guna2DataGridView2 (Tổng theo sản phẩm)
        Guna2DataGridView2.AutoGenerateColumns = False
        Guna2DataGridView2.Columns("DataGridViewTextBoxColumn1").DataPropertyName = "MaSP"
        Guna2DataGridView2.Columns("DataGridViewTextBoxColumn2").DataPropertyName = "TenSP"
        Guna2DataGridView2.Columns("DataGridViewTextBoxColumn3").DataPropertyName = "SoLuong"
        Guna2DataGridView2.Columns("DataGridViewTextBoxColumn4").DataPropertyName = "TongDoanhThu"
        LoadSanPham2()

        ' Vẽ chart 12 tháng (mẫu)
        SetupChart12Thang()
    End Sub

    ' ================== TẢI DỮ LIỆU ==================
    Private Sub LoadSanPham1()
        Dim sql As String = "SELECT MaSP, TenSP, DonGia FROM dbo.SanPham ORDER BY MaSP;"
        Dim dt As New DataTable()

        Try
            Using conn As New SqlConnection(connStr)
                Using da As New SqlDataAdapter(sql, conn)
                    da.Fill(dt)
                End Using
            End Using

            ' Gán DataSource qua BindingSource để dùng Filter
            bsSanPham.DataSource = dt
            Guna2DataGridView1.DataSource = bsSanPham

        Catch ex As Exception
            MessageBox.Show("Lỗi tải dữ liệu SanPham: " & ex.Message, "Lỗi",
                            MessageBoxButtons.OK, MessageBoxIcon.[Error])
        End Try
    End Sub

    Private Sub LoadSanPham2()
        Dim sql As String = "SELECT MaSP, TenSP, SoLuong, TongDoanhThu FROM dbo.DoanhThu ORDER BY MaSP;"
        Dim dt As New DataTable()

        Try
            Using conn As New SqlConnection(connStr)
                Using da As New SqlDataAdapter(sql, conn)
                    da.Fill(dt)
                End Using
            End Using

            Guna2DataGridView2.DataSource = dt

        Catch ex As Exception
            MessageBox.Show("Lỗi tải dữ liệu DoanhThu: " & ex.Message, "Lỗi",
                            MessageBoxButtons.OK, MessageBoxIcon.[Error])
        End Try
    End Sub

    ' ================== TÌM KIẾM REALTIME ==================
    Private Sub Guna2TextBox1_TextChanged(sender As Object, e As EventArgs) _
        Handles Guna2TextBox1.TextChanged

        If bsSanPham.DataSource Is Nothing Then Return

        Dim q As String = Guna2TextBox1.Text.Trim()
        If String.IsNullOrEmpty(q) Then
            bsSanPham.RemoveFilter()
            Return
        End If

        Dim s As String = EscapeLike(q)
        ' MaSP là varchar: convert sang string để LIKE hoạt động nhất quán
        bsSanPham.Filter =
            $"CONVERT(MaSP, 'System.String') LIKE '%{s}%' OR TenSP LIKE '%{s}%'"
    End Sub

    Private Shared Function EscapeLike(value As String) As String
        If String.IsNullOrEmpty(value) Then Return ""
        value = value.Replace("'", "''")
        value = value.Replace("[", "[[]")
        value = value.Replace("%", "[%]")
        value = value.Replace("_", "[_]")
        value = value.Replace("*", "[*]")
        Return value
    End Function

    ' ================== CHART 12 THÁNG (MẪU) ==================
    Private Sub SetupChart12Thang()
        Chart1.ChartAreas.Clear()
        Chart1.ChartAreas.Add(New ChartArea("ChartArea1"))

        Chart1.Series.Clear()
        Dim s As New Series("Doanh số") With {
            .ChartType = SeriesChartType.Column,
            .XValueType = ChartValueType.String,
            .IsXValueIndexed = True,
            .IsValueShownAsLabel = True
        }
        s("PointWidth") = "0.6"
        Chart1.Series.Add(s)

        Dim thang = {
            "Tháng 1", "Tháng 2", "Tháng 3", "Tháng 4", "Tháng 5", "Tháng 6",
            "Tháng 7", "Tháng 8", "Tháng 9", "Tháng 10", "Tháng 11", "Tháng 12"
        }
        Dim giatri = {70D, 82D, 72D, 20D, 15D, 80D, 40D, 55D, 60D, 90D, 75D, 100D}

        s.Points.DataBindXY(thang, giatri)

        With Chart1.ChartAreas(0)
            .AxisX.Interval = 1
            .AxisX.Title = "Tháng"
            .AxisY.Title = "Giá trị"
            .BackColor = Color.White
            .AxisX.LineColor = Color.Black
            .AxisY.LineColor = Color.Black
            .AxisX.MajorGrid.LineColor = Color.Gainsboro
            .AxisY.MajorGrid.LineColor = Color.Gainsboro
        End With
    End Sub


End Class
