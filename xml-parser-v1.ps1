# READ FROM FILE
[xml]$XmlIn = Get-Content D:\scripts\XML_RATEbankA2.xml

# RETRIEVE DATE FROM FILE IN FORM OF A STRING
$DateStr = $XmlIn.root.filials.filial.timevalue;

# CONVERT DATE STRING TO DateTime
[DateTime]$Date = $DateStr -as [DateTime];

# RETRIEVE CURRENT DATE
[DateTime]$CurrDate = Get-Date

# CHECK IF DATE AND TIME  FROM FILE IS EQUAL TO CURRENT
if(($CurrDate.Date -eq $Date.Date) -and ($Date.TimeOfDay -ge $CurrDate.TimeOfDay)) {
    $TimeDiff = New-TimeSpan -Start $CurrDate.ToUniversalTime() -End $Date.ToUniversalTime()
    $MinuteDiff = New-TimeSpan -Start $Date.ToUniversalTime() -End $Date.ToUniversalTime().AddMinutes(1)

    # TIME DIFF IS 1 MIN
    if($TimeDiff -le $MinuteDiff) {
        [System.Collections.ArrayList]$usdList= @('', '')
        [System.Collections.ArrayList]$eurList= @('', '', '')
        [System.Collections.ArrayList]$rubList= @()
        [System.Collections.ArrayList]$otherList= @()
        [System.Collections.ArrayList]$otherList= @()
        
        # WRITE CURRENCY NODES INTO SUBLISTS
        foreach ($value in $XmlIn.root.filials.filial.rates.value) {
            switch ($value.iso) {
                'USD' { 
                    if($value.HasAttribute('count_in')) {
                        $usdList[1] = $value
                    } else {
                        $usdList[0] = $value
                    }
                }
                'EUR' {
                    if ($value.HasAttribute('count_in')) {
                        if ($value.count_in -eq 'USD') {
                            $eurList[1] = $value
                        } else {
                            $eurList[2] = $value
                        } 
                    } else {
                        $eurList[0] = $value
                    }
                }
                'RUB' { $rubList.Add($value) }
                default { $otherList.Add($value) }      
            }
        }

        # JOIN SUBLISTS IN REQUIRED ORDER (CURRENCY PRIORITY)
        [System.Collections.ArrayList]$currencyList = @()
        foreach ($item in $usdList) {
            $currencyList.Add($item)
        }
        foreach ($item in $eurList) {
            $currencyList.Add($item)
        }
        foreach ($item in $rubList) {
            $currencyList.Add($item)
        }
        foreach ($item in $otherList) {
            $currencyList.Add($item)
        }

        # COPY INPUT FILE
        $XmlOut = $XmlIn
        
        # CHOOSE ALL xml ELEMENTS WITH "value" TAG
        $nodes = $XmlOut.SelectNodes("//value")

        # DELETE ALL "value"s
        foreach ($node in $nodes) {
            $node.ParentNode.RemoveChild($node)
        }

        # CHOOSE xml ELEMENT WITH "rates" TAG
        $ratesNode = $XmlOut.SelectSingleNode("//rates")

        # ADD CHILD NODES - CURRENCY RATES - IN REQUIRED ORDER
        foreach($item in $currencyList) {
            $ratesNode.AppendChild($item)
        }

        # SAVE EDITED COPY OF INPUT xml FILE
        $XmlOut.Save('D:\\scripts\\XML_test_3.xml')
    }
}
