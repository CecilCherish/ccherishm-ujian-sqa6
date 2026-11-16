
$xml = @'
<NewDataSet>
  <xs:schema id="NewDataSet" xmlns="" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:msdata="urn:schemas-microsoft-com:xml-msdata">
    <xs:element name="NewDataSet" msdata:IsDataSet="true" msdata:MainSource="TableName" msdata:UseCurrentLocale="true">
      <xs:complexType>
        <xs:choice minOccurs="0" maxOccurs="unbounded">
          <xs:element name="TableName">
            <xs:complexType>
              <xs:sequence>
                <xs:element name="ID_Transaksi" msdata:Caption="" type="xs:string" minOccurs="0" />
                <xs:element name="Waktu_Transaksi" msdata:Caption="" type="xs:string" minOccurs="0" />
                <xs:element name="No_Rekening" msdata:Caption="" type="xs:string" minOccurs="0" />
                <xs:element name="Channel_Core" msdata:Caption="" type="xs:string" minOccurs="0" />
                <xs:element name="Nominal_Core" msdata:Caption="" type="xs:string" minOccurs="0" />
                <xs:element name="Status_Core" msdata:Caption="" type="xs:string" minOccurs="0" />
                <xs:element name="Web_Channel" msdata:Caption="" type="xs:string" minOccurs="0" />
                <xs:element name="Web_Nominal" msdata:Caption="" type="xs:string" minOccurs="0" />
                <xs:element name="Web_Status" msdata:Caption="" type="xs:string" minOccurs="0" />
                <xs:element name="Audit_Status" msdata:Caption="" type="xs:string" minOccurs="0" />
                <xs:element name="Keterangan_Audit" msdata:Caption="" type="xs:string" minOccurs="0" />
              </xs:sequence>
            </xs:complexType>
          </xs:element>
        </xs:choice>
      </xs:complexType>
    </xs:element>
  </xs:schema>
</NewDataSet>
'@
$ds = New-Object System.Data.DataSet
$reader = New-Object System.IO.StringReader($xml)
$ds.ReadXml($reader)
Write-Output ("Tables count: " + $ds.Tables.Count)
if ($ds.Tables.Count -gt 0) {
    Write-Output ("Columns count: " + $ds.Tables[0].Columns.Count)
    foreach ($col in $ds.Tables[0].Columns) {
        Write-Output ("  " + $col.ColumnName)
    }
}
