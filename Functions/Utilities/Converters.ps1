function Get-EnabledBackgroundConverter {
    return @"
public class EnabledBackgroundConverter : IValueConverter
{
    public object Convert(object value, Type targetType, object parameter, CultureInfo culture)
    {
        return (bool)value ? "$($colors.InputBg)" : "$($colors.BorderColor)";
    }

    public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture)
    {
        throw new NotImplementedException();
    }
}
"@
}