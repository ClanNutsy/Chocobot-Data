param(
	[ValidateNotNull()]
	[PSCustomObject]
	$Duty
)

$dutyYamlTemplate = `
'name:
  en: "{0}"
  fr: "{1}"
  de: "{2}"
  ja: "{3}"
type: {4}
tags: []
lodestone:
  id: {5}
  image_url: {6}
  url: {7}
video_url:
  en: 
  fr: 
  de: 
  ja: 
pages:
'

$bossYamlTemplate = `
'
      - name:
          en: "{0}"
          fr: "{1}"
          de: "{2}"
          ja: "{3}"
        lodestone:
          id: {4}
          url: {5}'

$pageYamlTemplate = `
'  - bosses:{0}
    tags: []
    video_url:
      en:
      fr:
      de:
      ja:
    description:
      en: No strategy has been defined for this encounter yet!
      fr: No strategy has been defined for this encounter yet!
      de: No strategy has been defined for this encounter yet!
      ja: No strategy has been defined for this encounter yet!
    notes:
      en:
        - title: Why Not Contribute?
          text: Please consider contributing by visiting our GitHub site and uploading a strategy. Just click the title above!
      fr:
        - title: Why Not Contribute?
          text: Please consider contributing by visiting our GitHub site and uploading a strategy. Just click the title above!
      de:
        - title: Why Not Contribute?
          text: Please consider contributing by visiting our GitHub site and uploading a strategy. Just click the title above!
      ja:
        - title: Why Not Contribute?
          text: Please consider contributing by visiting our GitHub site and uploading a strategy. Just click the title above!
'

$dutyYaml = $dutyYamlTemplate -f `
	$Duty.name.na, `
	$Duty.name.fr, `
	$Duty.name.de, `
	$Duty.name.jp, `
	$Duty.type, `
	$Duty.lodestoneId, `
	$Duty.lodestoneImageUri, `
	$Duty.lodestoneUri

foreach ($encounter in $Duty.encounters)
{
	$bossYaml = ""
	if ($encounter.bosses.Count -eq 0)
	{
		$bossYaml = " []"
	}
	else
	{
		foreach ($boss in $encounter.bosses)
		{
			$bossYaml += $bossYamlTemplate -f `
				$Duty.bosses[$boss].name.na, `
				$Duty.bosses[$boss].name.fr, `
				$Duty.bosses[$boss].name.de, `
				$Duty.bosses[$boss].name.jp, `
				$Duty.bosses[$boss].lodestoneId, `
				$Duty.bosses[$boss].lodestoneUri
		}
	}
	
	$dutyYaml += $pageYamlTemplate -f $bossYaml
}

$fileName = $Duty.name.na.Replace('(', '').Replace(')', '').Replace("'", '').Replace('<i>', '').Replace('</i>', '').Replace(':', '').Replace('.', '').Replace(' - ', '_').Replace(' ', '_').ToLowerInvariant()

$dutyYaml | % { [System.Web.HttpUtility]::HtmlDecode($_) } | Out-File "./duties/$fileName.yml" -Encoding UTF8
