<#
.SYNOPSIS

Set a status on Slack.
.DESCRIPTION

Given a status and icon string, call Slack's web API and set the status for a given API token.
.PARAMETER status

A string containing the desired status text.
.PARAMETER icon

A string containing the icon to set along with the status text.
.PARAMETER token

A Slack API token.
.EXAMPLE

Set-SlackStatus "WFH" ":house_with_garden:" "xoxp-****"

Set the status for the given token to WFH with the icon :house_with_garden:

.EXAMPLE
Set-SlackStatus "Commuting" ":bus:" $slackToken

Set the status for the given token to Commuting with the icon :bus:. Presupposes that a variable $slackToken containing the token exists in scope.
#>
function Set-SlackStatus($status, $icon, $token)
{
    $rawProfile = @"
    {
        "status_text": "$status",
        "status_emoji": "$icon"
    }
"@
    $encodedProfile = [uri]::EscapeDataString($rawProfile)
    $uri = "slack.com/api/users.profile.set?token=$token&profile=$encodedProfile"

    Invoke-WebRequest -Uri $uri
}
