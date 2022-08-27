$window_title = "UH OH!"
$window_message = "yOu HaVe BeEn HaCkEd!!!1!@!"

[System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms')
[System.Windows.Forms.MessageBox]::Show($window_message,$window_title)
