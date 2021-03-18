using namespace System.Windows
using namespace System.Collections.ObjectModel

. "$(Get-Location)\WpfLoader.ps1"

Add-Type -AssemblyName presentationframework, presentationcore
Add-Type -AssemblyName System.Windows
Add-Type -AssemblyName System.Collections

class Relay: System.Windows.Input.ICommand {
    Relay([Action[object]]$Command){
        $this.command = $Command;
    }
    
    hidden [Action[object]]$command;
    [void]add_CanExecuteChanged ([System.EventHandler]$handler){}
    [void]remove_CanExecuteChanged ([System.EventHandler]$handler){}

    [bool]CanExecute([object]$arg) {return  $true; }
    [void]Execute ([object]$arg){ $this.command?.Invoke($arg); }
} 

class ShowMessageCommand : System.Windows.Input.ICommand {
    [string]$Message
    ShowMessageCommand([string]$message) { 
        $this.Message = $message
    }

    [void]add_CanExecuteChanged ([System.EventHandler]$handler){}
    [void]remove_CanExecuteChanged ([System.EventHandler]$handler){}

    [bool]CanExecute([object]$arg) {return  $true; }
    [void]Execute ([object]$arg){ Write-Host $this.Message; }
}

class MainWindowVM {
    [string]$Title;
    [string]$Content; 
    [string]$Uri;
    [string]$buttonContent
    [object]$Item;
    [System.Collections.ObjectModel.ObservableCollection[object]]$Items;
    MainWindowVM () {
        $this.Items = [System.Collections.ObjectModel.ObservableCollection[object]]::new()
        $this.Title = "title"
        $this.Content = "content"
        $this.buttonContent = "click!"
        $this.ShowCommand = [Relay]::new({ param($p) Write-Host $p.Title; Show-MessageBox "message"});
        $this.Item = @{Title=$this.Title; Content=$this.Content}
        $this.Items.Add($this.Item)
    }

    [System.Windows.Input.ICommand]$ShowCommand;
}

function Show-MessageBox{
    Param([string]$message)
    [System.Windows.MessageBox]::Show("$message")
}

[System.Windows.Window]$mainWindow = [WindowLoader]::LoadWindow("MainWindow.xaml", [MainWindowVM]::new())

$mainWindow.button1.Add_Click({
    #$wpf.MainWindow.Close()
});

$mainWindow.Add_Loaded({
    #Update-Cmd
})
#Things to load when the WPF form is rendered aka drawn on screen
$mainWindow.Add_ContentRendered({
    #Update-Cmd
})

$mainWindow.add_Closing({
    $msg = "bye bye !"
    write-host $msg
})

#endregion Load, Draw and closing form events
#End of load, draw and closing form events

#HINT: to update progress bar and/or label during WPF Form treatment, add the following:
# ... to re-draw the form and then show updated controls in realtime ...
$mainWindow.Dispatcher.Invoke("Render",[action][scriptblock]{})


# Load the form:
# Older way >>>>> $wpf.MyFormName.ShowDialog() | Out-Null >>>>> generates crash if run multiple times
# Newer way >>>>> avoiding crashes after a couple of launches in PowerShell...
# USing method from https://gist.github.com/altrive/6227237 to avoid crashing Powershell after we re-run the script after some inactivity time or if we run it several times consecutively...
$async = $mainWindow.Dispatcher.InvokeAsync({
    $mainWindow.ShowDialog() | Out-Null
})
$async.Wait() | Out-Null

# $mainWindow.ShowDialog() 