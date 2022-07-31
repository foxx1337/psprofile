$mustStart = $false;
$agentPidFile = "$HOME\.ssh\PID"
$sshAgent = "D:\src\toolz\Git\usr\bin\ssh-agent.exe"

$oldAgentPid = (Get-Content $agentPidFile -ErrorAction Ignore | Out-String).Trim()

if (!$oldAgentPid) {
    Write-Output "There was no file about an agent running"
} else {
    Write-Output "Found old agent file pointing towards Id=$oldAgentPid"
}

$runningAgentPid = (Get-Process -Name "ssh-agent" -ErrorAction Ignore).Id

if (!$runningAgentPid) {
    Write-Output "There is no agent running"
    $mustStart = $true
} else {
    Write-Output "Agent is running at $runningAgentPid"
}

if ($oldAgentPid -ne $runningAgentPid) {
    Write-Output "They're not equal!"
    $mustStart = $true
}

if ($mustStart) {
    if ($runningAgentPid) {
        Stop-Process -Id $runningAgentPid
    }

    $newAgentPid = ""
    $authSock = ""
    $output = (& $sshAgent).Split([System.Environment]::NewLine)
    if ($output[0] -match '^SSH_AUTH_SOCK=/tmp/(ssh-.+/agent.\d+); export SSH_AUTH_SOCK;$') {
        $authSock = "$Env:temp\" + $Matches[1] -replace "/", "\"
        Write-Output "Auth sock at $authSock"
        #$Env:SSH_AUTH_SOCK = $authSock
        #setx SSH_AUTH_SOCK $authSock
        [System.Environment]::SetEnvironmentVariable("SSH_AUTH_SOCK", "$authSock", [System.EnvironmentVariableTarget]::User)
        $Env:SSH_AUTH_SOCK=$authSock
    } else {
        Write-Output "No auth sock"
    }

    $newAgentPid = (Get-Process -Name ssh-agent).Id
    if ($newAgentPid) {
        Write-Output "ssh-agent PID at $newAgentPid"
        Write-Output $newAgentPid > $agentPidFile
        #$Env:SSH_AGENT_PID = $newAgentPid
        #setx SSH_AGENT_PID $newAgentPid
        [System.Environment]::SetEnvironmentVariable("SSH_AGENT_PID", "$newAgentPid", [System.EnvironmentVariableTarget]::User)
        $Env:SSH_AGENT_PID=$newAgentPid
    } else {
        Write-Output "No ssh-agent process!"
    }
}

Update-SessionEnvironment
