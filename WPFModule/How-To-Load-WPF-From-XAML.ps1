using namespace System.Windows
using namespace System.Collections.ObjectModel

Add-Type -AssemblyName presentationframework, presentationcore
Add-Type -AssemblyName System.Windows
Add-Type -AssemblyName System.Collections
function Get-WPFObject {
    Param(
        [string] $inputXML,
        [string] $XamlPath)
    # Load a WPF GUI from a XAML file build with Visual Studio
    $wpf = @{ }
    # NOTE: Either load from a XAML file or paste the XAML file content in a "Here String"
    if([string]::IsNullOrEmpty($inputXML)){
        $inputXML = Get-Content -Path $XamlPath 
        #".\WPFGUIinTenLines\MainWindow.xaml"
    }
    
    [xml]$xaml = Get-CleanXML -RawInput $inputXML
    $NamedNodes = Get-XamlNamedNodes -Xml $xaml

    $reader = ([System.Xml.XmlNodeReader]::new($xaml))
    $form = [Windows.Markup.XamlReader]::Load($reader)

    $NamedNodes | ForEach-Object {$wpf.Add($_.Name, $form.FindName($_.Name))}
    #Get the form name to be used as parameter in functions external to form...
    $rootName = $NamedNodes[0].Name

    return $wpf
}

function Get-CleanXML {
    Param([string]$RawInput)
    return $($RawInput -replace 'mc:Ignorable="d"','' -replace "x:N",'N' -replace 'x:Class=".*?"','' -replace 'd:DesignHeight="\d*?"','' -replace 'd:DesignWidth="\d*?"','')
}
function Get-XamlNamedNodes {
    Param([xml]$Xml)    
    $namedNodes = $Xml.SelectNodes("//*[@*[contains(translate(name(.),'n','N'),'Name')]]")    
    return $namedNodes
}

class Relay: System.Windows.Input.ICommand {
    [Action[object]]$command;
    Relay([Action[object]]$Command){
        $this.command = $Command;
    }

    [void]add_CanExecuteChanged ([System.EventHandler]$handler){}
    [void]remove_CanExecuteChanged ([System.EventHandler]$handler){}

    [bool]CanExecute([object]$arg) {return  $true; }
    [void]Execute ([object]$arg){ Write-Host $arg; $this.command?.Invoke($arg); }
}

class MainWindowVM {
    [string]$Title = "test";
    [string]$Content = "content";
    [string]$Uri;
    [string]$buttonContent = "click!"
    [object]$Item = @{Title=$Title; Content=$Content}
    [ObservableCollection[object]]$Items
    MainWindowVM(){
        $this.Items = [ObservableCollection[object]]::new()
    }
    $commandAction = { param($arg) $this.Items.Add($Item) }
    [System.Windows.Input.ICommand]$AddCommand = [Relay]::new($commandAction)
}

$inputXml = '<Window x:Class="WpfApp1.MainWindow"
x:Name="MainWindow"
xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
xmlns:d="http://schemas.microsoft.com/expression/blend/2008"
xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
xmlns:local="clr-namespace:WpfApp1"
mc:Ignorable="d"
Title="MainWindow" Height="450" Width="800">
    <Window.Resources>
        <Style TargetType="Button">
            <Setter Property="Background" Value="Gray" />
            <Setter Property="Foreground" Value="DarkGray"/>
        </Style>
    </Window.Resources>
    <Grid>
        <Grid.RowDefinitions>
            <RowDefinition Height="*"/>
            <RowDefinition Height="5*"/>
            <RowDefinition Height="*"/>
        </Grid.RowDefinitions>
        <Grid.ColumnDefinitions>
            <ColumnDefinition Width="*"/>
            <ColumnDefinition Width="5*"/>
            <ColumnDefinition Width="*"/>
        </Grid.ColumnDefinitions>
        <StackPanel Grid.Row="1" Grid.Column="1">
            <TextBox x:Name="_Title" Text="{Binding Title, Mode=TwoWay, UpdateSourceTrigger=PropertyChanged}"></TextBox>
            <TextBlock x:Name="Title" Text="{Binding Title, Mode=TwoWay}"></TextBlock>
            <Button x:Name="button1"
                Content="{Binding buttonContent}" Command="{Binding AddCommand}" CommandParameter="{Binding Item}"></Button>
        </StackPanel>
    </Grid>
</Window>
';
#Define events functions
#region Load, Draw (render) and closing form events
#Things to load when the WPF form is loaded aka in memory
$wpf = $(Get-WPFObject -inputXML $inputXml)

$wpf.MainWindow.DataContext = [MainWindowVM]::new()

$wpf.button1.Add_Click({
    #$wpf.MainWindow.Close()
});

$wpf.MainWindow.Add_Loaded({
    #Update-Cmd
})
#Things to load when the WPF form is rendered aka drawn on screen
$wpf.MainWindow.Add_ContentRendered({
    #Update-Cmd
})
$wpf.MainWindow.add_Closing({
    $msg = "bye bye !"
    write-host $msg
})

#endregion Load, Draw and closing form events
#End of load, draw and closing form events

#HINT: to update progress bar and/or label during WPF Form treatment, add the following:
# ... to re-draw the form and then show updated controls in realtime ...
$wpf.MainWindow.Dispatcher.Invoke("Render",[action][scriptblock]{})


# Load the form:
# Older way >>>>> $wpf.MyFormName.ShowDialog() | Out-Null >>>>> generates crash if run multiple times
# Newer way >>>>> avoiding crashes after a couple of launches in PowerShell...
# USing method from https://gist.github.com/altrive/6227237 to avoid crashing Powershell after we re-run the script after some inactivity time or if we run it several times consecutively...
$async = $wpf.MainWindow.Dispatcher.InvokeAsync({
    $wpf.MainWindow.ShowDialog() | Out-Null
})
$async.Wait() | Out-Null