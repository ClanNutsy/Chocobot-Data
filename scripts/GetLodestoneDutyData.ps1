param()

#

$regions = @("na", "eu", "fr", "de", "jp")

#

$categories = New-Object System.Collections.Generic.List[Object]

$categories += @{
	"Name" = "Dungeon"
	"CategoryId" = 2
	"TotalPageCount" = 2
}

$categories += @{
	"Name" = "Trial"
	"CategoryId" = 4
	"TotalPageCount" = 2
}

$categories += @{
	"Name" = "Raid"
	"CategoryId" = 5
	"TotalPageCount" = 2
}

$categories += @{
	"Name" = "Ultimate Raid"
	"CategoryId" = 28
	"TotalPageCount" = 1
}

#

$dutyRegex = New-Object Regex('<a href="(?<lodestoneUri>.+)" class="db_popup db-table__txt--detail_link">(?<name>.+)<\/a>')
$duties = [ordered] @{}

foreach ($region in $regions)
{
	foreach ($category in $categories)
	{
		for ($i = 1; $i -le $category.TotalPageCount; $i++)
		{
			$uri = "https://$region.finalfantasyxiv.com/lodestone/playguide/db/duty/?category2=$($category.CategoryId)"
		
			if ($i -gt 1)
			{
				$uri += "&page=$i"
			}
			
			$response = Invoke-WebRequest -Method GET -Uri $uri
			$matches = $dutyRegex.Matches($response.Content)
			
			foreach ($match in $matches)
			{
				$lodestoneUri = $match.Groups['lodestoneUri'].Value
				$lodestoneId = $lodestoneUri.Split("/", [StringSplitOptions]::RemoveEmptyEntries)[-1]
				$dutyName = $match.Groups['name'].Value
				
				if ($duties.Keys -contains $lodestoneId)
				{
					$duty = $duties[$lodestoneId]
				}
				else
				{
					$duty = [PSCustomObject]@{
						"bosses" = [ordered] @{}
						"encounters" = New-Object System.Collections.Generic.List[Object]
						"lodestoneId" = $lodestoneId
						"lodestoneUri" = $lodestoneUri
						"name" = [ordered] @{}
						"type" = $category.Name
					}
					
					$duties[$lodestoneId] = $duty
				}
				
				$duty.name[$region] = $dutyName
			}
			
			Start-Sleep -Seconds 1
		}
	}
}

#

$bossListRegex = '<ul class="db-view__data__boss_list">(.+?)<\/ul>'
$bossNameRegex = '<li.+?<a href="(?<lodestoneUri>.+?)".+?<strong>(?<name>.+?)</strong>'

foreach ($duty in $duties.Values)
{
	foreach ($region in $regions)
	{
		$uri = "https://$region.finalfantasyxiv.com" + $duty.LodestoneUri
	
		$response = Invoke-WebRequest -Method GET -Uri $uri
		$bossListMatches = [Regex]::Matches($response.Content, $bossListRegex, [System.Text.RegularExpressions.RegexOptions]::Singleline)
		
		for ($i = 0; $i -lt $bossListMatches.Count; $i++)
		{
			$encounter = $i + 1
			$bossListMatch = $bossListMatches[$i]
			
			$bossLodestoneIds = New-Object System.Collections.Generic.List[String]
			
			$bossNameMatches = [Regex]::Matches($bossListMatch.Value, $bossNameRegex, [System.Text.RegularExpressions.RegexOptions]::Singleline)
			
			foreach ($bossNameMatch in $bossNameMatches)
			{
				$lodestoneUri = $bossNameMatch.Groups['lodestoneUri'].Value
				$lodestoneId = $lodestoneUri.Split("/", [StringSplitOptions]::RemoveEmptyEntries)[-1]
				$bossName = $bossNameMatch.Groups['name'].Value
				
				if ($duty.bosses.Keys -contains $lodestoneId)
				{
					$boss = $duty.bosses[$lodestoneId]
				}
				else
				{
					$boss = [PSCustomObject]@{
						"lodestoneId" = $lodestoneId
						"lodestoneUri" = $lodestoneUri
						"name" = [ordered] @{}
					}
					
					$duty.bosses[$lodestoneId] = $boss
				}
				
				$boss.name[$region] = $bossName
				$bossLodestoneIds += $lodestoneId
			}
			
			if ($duty.encounters.Count -lt $encounter)
			{
				$duty.encounters += [PSCustomObject]@{
					"bosses" = $bossLodestoneIds
				}
			}
		}
		
		Start-Sleep -Seconds 1
	}
}

#

$duties.Values | ConvertTo-Json -Depth 10 | % { [System.Web.HttpUtility]::HtmlDecode($_) } | Out-File "duties.json" -Encoding UTF8

return $duties.Values
