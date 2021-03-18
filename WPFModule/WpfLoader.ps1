using namespace System.Windows
using namespace System.Markup

Add-Type -AssemblyName PresentationFramework, PresentationCore -Verbose
Add-Type -AssemblyName System.Drawing, PresentationCore

# class WpfWindow {
#     WpfWindow([string] $xamlFilePath) {
#         Initialize-Components -source $this -$xamlFilePath $xamlFilePath
#     }
# }

# function Initialize-Components
# {
#     Param ([object]$source, [string]$xamlFilePath) 
#     [System.Uri] $resourceLocater = [System.Uri]::new("$(Get-Location)/$xamlFilePath", [System.UriKind]::Absolute)
#     $relativeUri = $resourceLocater.MakeRelative([System.Uri]::new($(Get-Location), [System.UriKind]::Absolute));
#     return $resourceLocater
#     [System.Windows.Application]::LoadComponent($source, $relativeUri)
#     return ([System.Windows.Window]$source)
# }

class WindowLoader {
    static [object] LoadWindow($xamlFilePath, $viewmodel) {
        [HashTable]$WpfComponents = Get-WPFObject -XamlPath $xamlFilePath
        $WindowName = $xamlFilePath.Split('.')[0]
        $WpfComponents[$WindowName]
        $WpfComponents[$WindowName].DataContext = $viewmodel
        # $window[0].ShowDialog()
        return $WpfComponents[$WindowName]
    }
}

function Get-WPFObject 
{
    Param ([string] $inputXML, [string] $XamlPath)
    # Load a WPF GUI from a XAML file build with Visual Studio
    $wpf = @{ }
    # NOTE: Either load from a XAML file or paste the XAML file content in a "Here String"
    if([string]::IsNullOrEmpty($inputXML)){
        $inputXML = Get-Content -Path $XamlPath 
        #".\WPFGUIinTenLines\MainWindow.xaml"
    }
    
    [xml]$xaml = Get-CleanXML($inputXML)
    $NamedNodes = Get-XamlNamedNodes($xaml)

    $reader = ([System.Xml.XmlNodeReader]::new($xaml))
    $form = [Windows.Markup.XamlReader]::Load($reader)

    $NamedNodes `
    | ForEach-Object {$wpf.Add($_.Name, $form.FindName($_.Name))}
    #Get the form name to be used as parameter in functions external to form...
    $rootName = $NamedNodes[0].Name

    return $wpf
}

function Get-CleanXML 
{
    Param([string]$RawInput) 
    return $($RawInput -replace 'mc:Ignorable="d"','' -replace "x:N",'N' -replace 'x:Class=".*?"','' -replace 'd:DesignHeight="\d*?"','' -replace 'd:DesignWidth="\d*?"','')
}

function Get-XamlNamedNodes
{   
    Param([xml]$Xml) 
 
    $namedNodes = $Xml.SelectNodes("//*[@*[contains(translate(name(.),'n','N'),'Name')]]")    
    return $namedNodes
}