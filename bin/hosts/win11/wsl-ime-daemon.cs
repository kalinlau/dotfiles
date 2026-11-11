// ==============================================================================
// WSL-IME Daemon: Ultra-fast Input Method Auto-Switch Daemon for Windows 11 & WSL2
//
// File:        wsl-ime-daemon.cs
// Description: Resident background TCP daemon managing Windows 11 IME (Microsoft Pinyin,
//              Sogou, etc.) state via Win32 Imm32/User32 APIs for WSL2 editors (Vim/Neovim).
// Author:      Jialin Liu (LAU Kalin) <laukalin24@gmail.com>
// License:     MIT License (see LICENSE file)
// ==============================================================================

using System;
using System.IO;
using System.Net;
using System.Net.Sockets;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading;

namespace WslIme
{
    /// <summary>
    /// Core daemon process providing sub-millisecond IME state inspection and switching
    /// over a local loopback TCP socket (default port 8765).
    /// </summary>
    class Program
    {
        #region Win32 API Imports & Constants

        /// <summary>
        /// Retrieves a handle to the foreground window (the window with which the user is currently working).
        /// </summary>
        [DllImport("user32.dll")]
        static extern IntPtr GetForegroundWindow();

        /// <summary>
        /// Retrieves the identifier of the thread that created the specified window and, optionally,
        /// the identifier of the process that created the window.
        /// </summary>
        [DllImport("user32.dll", SetLastError = true)]
        static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint lpdwProcessId);

        /// <summary>
        /// Retrieves the active input locale identifier (formerly called keyboard layout) for the specified thread.
        /// </summary>
        [DllImport("user32.dll")]
        static extern IntPtr GetKeyboardLayout(uint idThread);

        /// <summary>
        /// Retrieves the default window handle to the IME class associated with the specified window.
        /// </summary>
        [DllImport("imm32.dll")]
        static extern IntPtr ImmGetDefaultIMEWnd(IntPtr hWnd);

        /// <summary>
        /// Sends the specified message to a window or windows.
        /// </summary>
        [DllImport("user32.dll", CharSet = CharSet.Auto)]
        static extern IntPtr SendMessage(IntPtr hWnd, uint Msg, IntPtr wParam, IntPtr lParam);

        /// <summary>
        /// Places (posts) a message in the message queue associated with the thread that created
        /// the specified window and returns without waiting for the thread to process the message.
        /// </summary>
        [DllImport("user32.dll", CharSet = CharSet.Auto)]
        static extern bool PostMessage(IntPtr hWnd, uint Msg, IntPtr wParam, IntPtr lParam);

        /// <summary>
        /// Attaches the calling process to the console of the specified process (e.g. parent console).
        /// </summary>
        [DllImport("kernel32.dll")]
        static extern bool AttachConsole(int dwProcessId);

        /// <summary>
        /// Detaches the calling process from its console.
        /// </summary>
        [DllImport("kernel32.dll")]
        static extern bool FreeConsole();

        /// <summary>
        /// Win32 RECT structure representing coordinates of a rectangle.
        /// </summary>
        [StructLayout(LayoutKind.Sequential)]
        struct RECT
        {
            public int Left, Top, Right, Bottom;
        }

        /// <summary>
        /// Contains information about a GUI thread (active window, focus control, caret, etc.).
        /// Required for locating the inner focused terminal control inside modern frameworks
        /// such as Windows Terminal (wt.exe) or Electron/VSCode.
        /// </summary>
        [StructLayout(LayoutKind.Sequential)]
        struct GUITHREADINFO
        {
            public int cbSize;
            public int flags;
            public IntPtr hwndActive;
            public IntPtr hwndFocus;
            public IntPtr hwndCapture;
            public IntPtr hwndMenuOwner;
            public IntPtr hwndMoveSize;
            public IntPtr hwndCaret;
            public RECT rcCaret;
        }

        /// <summary>
        /// Retrieves information about the active window or a specified GUI thread.
        /// </summary>
        [DllImport("user32.dll")]
        static extern bool GetGUIThreadInfo(uint idThread, ref GUITHREADINFO lpgui);

        // Win32 Window Message Constants for IME Interaction
        const uint WM_IME_CONTROL = 0x0283;             // Sent to IME default window to query/modify IME
        const int IMC_GETCONVERSIONMODE = 0x0001;       // Command to retrieve current conversion mode
        const int IMC_SETCONVERSIONMODE = 0x0002;       // Command to set conversion mode
        const int IMC_GETOPENSTATUS = 0x0005;           // Command to get open/closed status (1=Open, 0=Closed)
        const int IMC_SETOPENSTATUS = 0x0006;           // Command to set open/closed status
        const uint WM_INPUTLANGCHANGEREQUEST = 0x0050; // Message to request keyboard layout change

        // Conversion mode flags for IME
        const int IME_CMODE_ALPHANUMERIC = 0x0000;      // Direct alphanumeric / English input mode
        const int IME_CMODE_NATIVE = 0x0001;            // Native CJK character conversion mode

        #endregion

        #region State & Fields

        /// <summary>
        /// Default TCP port to bind and listen on.
        /// </summary>
        static int port = 8765;

        /// <summary>
        /// Whether verbose debug logging to standard console is enabled.
        /// </summary>
        static bool isDebug = false;

        /// <summary>
        /// Flag controlling the main TCP server listener loop.
        /// </summary>
        static volatile bool isRunning = true;

        /// <summary>
        /// TCP listener instance.
        /// </summary>
        static TcpListener server = null;

        /// <summary>
        /// Persistent diagnostic log path in Windows LocalAppData (%LOCALAPPDATA%\wsl-ime\daemon.log).
        /// </summary>
        static readonly string logPath = Path.Combine(
            Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
            @"wsl-ime\daemon.log"
        );

        #endregion

        #region Logging

        /// <summary>
        /// Appends a timestamped log message to %LOCALAPPDATA%\wsl-ime\daemon.log.
        /// If debug mode is active, also writes to console stdout.
        /// </summary>
        /// <param name="msg">Message string to record.</param>
        static void Log(string msg)
        {
            string line = string.Format("[{0:yyyy-MM-dd HH:mm:ss.fff}] {1}\r\n", DateTime.Now, msg);
            try
            {
                string dir = Path.GetDirectoryName(logPath);
                if (!Directory.Exists(dir))
                {
                    Directory.CreateDirectory(dir);
                }
                File.AppendAllText(logPath, line);
            }
            catch
            {
                // Never allow logging failures to disrupt core daemon operations
            }

            if (isDebug)
            {
                Console.Write(line);
            }
        }

        #endregion

        #region IME State Query & Control

        /// <summary>
        /// Discovers the active foreground window and retrieves its corresponding IME window handle.
        /// Accurately handles child controls in modern terminal host windows (Windows Terminal ConPTY).
        /// </summary>
        /// <param name="threadId">Outputs the thread ID owning the foreground window.</param>
        /// <param name="foregroundHwnd">Outputs the top-level foreground window handle.</param>
        /// <returns>IME window handle (ImmGetDefaultIMEWnd), or IntPtr.Zero if unavailable.</returns>
        static IntPtr GetTargetIMEWnd(out uint threadId, out IntPtr foregroundHwnd)
        {
            foregroundHwnd = GetForegroundWindow();
            if (foregroundHwnd == IntPtr.Zero)
            {
                threadId = 0;
                return IntPtr.Zero;
            }

            uint processId;
            threadId = GetWindowThreadProcessId(foregroundHwnd, out processId);

            IntPtr targetHwnd = foregroundHwnd;

            // Attempt to obtain the exact focused child window (e.g. Windows Terminal child control)
            GUITHREADINFO gui = new GUITHREADINFO();
            gui.cbSize = Marshal.SizeOf(gui);
            if (GetGUIThreadInfo(threadId, ref gui))
            {
                if (gui.hwndFocus != IntPtr.Zero)
                {
                    targetHwnd = gui.hwndFocus;
                }
                else if (gui.hwndActive != IntPtr.Zero)
                {
                    targetHwnd = gui.hwndActive;
                }
            }

            IntPtr imeWnd = ImmGetDefaultIMEWnd(targetHwnd);
            if (imeWnd == IntPtr.Zero && targetHwnd != foregroundHwnd)
            {
                imeWnd = ImmGetDefaultIMEWnd(foregroundHwnd);
            }

            return imeWnd;
        }

        /// <summary>
        /// Checks whether the foreground window is currently set to Chinese input mode.
        /// Inspects both input locale (HKL) and internal IME conversion status (OpenStatus / ConversionMode).
        /// </summary>
        /// <returns>True if Chinese mode is active; false if English/Alphanumeric.</returns>
        static bool IsChineseMode()
        {
            uint threadId;
            IntPtr fgHwnd;
            IntPtr imeWnd = GetTargetIMEWnd(out threadId, out fgHwnd);

            // 1. Check keyboard layout (HKL)
            if (threadId != 0)
            {
                IntPtr hkl = GetKeyboardLayout(threadId);
                int langId = (int)(hkl.ToInt64() & 0xFFFF);
                // 0x0409 = English (United States). If active layout is US English, it is definitely English.
                if (langId == 0x0409)
                {
                    return false;
                }
            }

            if (imeWnd == IntPtr.Zero)
            {
                return false;
            }

            // 2. Check IME OpenStatus (0 = Closed/English, 1 = Open/Chinese)
            long openStatus = SendMessage(imeWnd, WM_IME_CONTROL, (IntPtr)IMC_GETOPENSTATUS, IntPtr.Zero).ToInt64();
            if (openStatus == 0)
            {
                return false;
            }

            // 3. Check ConversionMode (bit 0: 1 = Chinese/Native, 0 = Alphanumeric)
            long convMode = SendMessage(imeWnd, WM_IME_CONTROL, (IntPtr)IMC_GETCONVERSIONMODE, IntPtr.Zero).ToInt64();
            return (convMode & IME_CMODE_NATIVE) != 0;
        }

        /// <summary>
        /// Programmatically switches the foreground window between English and Chinese input mode.
        /// </summary>
        /// <param name="chinese">True to activate Chinese mode; false to force English mode.</param>
        static void SetChineseMode(bool chinese)
        {
            uint threadId;
            IntPtr fgHwnd;
            IntPtr imeWnd = GetTargetIMEWnd(out threadId, out fgHwnd);

            if (threadId != 0)
            {
                IntPtr hkl = GetKeyboardLayout(threadId);
                int langId = (int)(hkl.ToInt64() & 0xFFFF);

                // If user uses dual keyboard layouts and the active layout is already English US:
                if (!chinese && langId == 0x0409)
                {
                    return; // already pure English layout
                }
            }

            if (imeWnd == IntPtr.Zero)
            {
                return;
            }

            if (!chinese)
            {
                // Switch to English: Close IME status & clear conversion mode
                SendMessage(imeWnd, WM_IME_CONTROL, (IntPtr)IMC_SETOPENSTATUS, (IntPtr)0);
                SendMessage(imeWnd, WM_IME_CONTROL, (IntPtr)IMC_SETCONVERSIONMODE, (IntPtr)IME_CMODE_ALPHANUMERIC);
            }
            else
            {
                // Switch to Chinese: Open IME status & set native conversion mode
                SendMessage(imeWnd, WM_IME_CONTROL, (IntPtr)IMC_SETOPENSTATUS, (IntPtr)1);
                SendMessage(imeWnd, WM_IME_CONTROL, (IntPtr)IMC_SETCONVERSIONMODE, (IntPtr)IME_CMODE_NATIVE);
            }
        }

        #endregion

        #region Client Request Handling

        /// <summary>
        /// Dispatches individual incoming client TCP connections from WSL/Vim.
        /// Operates with NoDelay enabled to guarantee sub-millisecond round-trip response.
        /// </summary>
        /// <param name="clientObj">TcpClient instance passed from ThreadPool.</param>
        static void HandleClient(object clientObj)
        {
            TcpClient client = (TcpClient)clientObj;
            try
            {
                // Disable Nagle's algorithm for sub-millisecond command-response latency
                client.NoDelay = true;

                using (NetworkStream stream = client.GetStream())
                using (StreamReader reader = new StreamReader(stream, Encoding.ASCII))
                using (StreamWriter writer = new StreamWriter(stream, Encoding.ASCII) { AutoFlush = true })
                {
                    string line;
                    while ((line = reader.ReadLine()) != null)
                    {
                        line = line.Trim();
                        if (string.IsNullOrEmpty(line))
                            continue;

                        Log("Received cmd: " + line);

                        if (line == "get")
                        {
                            bool zh = IsChineseMode();
                            writer.WriteLine(zh ? "zh" : "en");
                        }
                        else if (line == "set:en")
                        {
                            SetChineseMode(false);
                            writer.WriteLine("ok");
                        }
                        else if (line == "set:zh")
                        {
                            SetChineseMode(true);
                            writer.WriteLine("ok");
                        }
                        else if (line == "toggle")
                        {
                            bool zh = IsChineseMode();
                            SetChineseMode(!zh);
                            writer.WriteLine(!zh ? "zh" : "en");
                        }
                        else if (line == "ping")
                        {
                            writer.WriteLine("pong");
                        }
                        else if (line == "stop")
                        {
                            writer.WriteLine("ok");
                            isRunning = false;
                            server.Stop();
                            Environment.Exit(0);
                            return;
                        }
                        else if (line == "quit" || line == "exit")
                        {
                            break;
                        }
                        else
                        {
                            writer.WriteLine("err:unknown_cmd");
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                Log("Client error: " + ex.Message);
            }
            finally
            {
                client.Close();
            }
        }

        #endregion

        #region Application Entry Point

        /// <summary>
        /// Daemon entry point.
        /// Supports CLI arguments: --port &lt;number&gt;, --debug, --stop.
        /// </summary>
        /// <param name="args">Command line arguments.</param>
        static void Main(string[] args)
        {
            // Global unhandled exception handler to catch any unexpected issues
            AppDomain.CurrentDomain.UnhandledException += (s, e) =>
            {
                Log("FATAL UNHANDLED EXCEPTION: " + e.ExceptionObject);
            };

            Log(string.Format("Process started (PID: {0}, Args: '{1}')", 
                System.Diagnostics.Process.GetCurrentProcess().Id,
                string.Join(" ", args)));

            // Parse command line arguments
            for (int i = 0; i < args.Length; i++)
            {
                if (args[i] == "--port" && i + 1 < args.Length)
                {
                    int.TryParse(args[++i], out port);
                }
                else if (args[i] == "--debug")
                {
                    isDebug = true;
                    AttachConsole(-1);
                }
                else if (args[i] == "--stop")
                {
                    // Send stop command to running daemon instance
                    try
                    {
                        using (TcpClient client = new TcpClient("127.0.0.1", port))
                        using (StreamWriter writer = new StreamWriter(client.GetStream(), Encoding.ASCII) { AutoFlush = true })
                        {
                            writer.WriteLine("stop");
                        }
                        Console.WriteLine("Sent stop signal to daemon on port " + port);
                    }
                    catch
                    {
                        Console.WriteLine("No running daemon found responding on port " + port);
                    }
                    return;
                }
            }

            // Bind to IPAddress.Any (0.0.0.0) so WSL2 mirrored networking, NAT gateway,
            // and local Windows clients can all reliably communicate.
            try
            {
                server = new TcpListener(IPAddress.Any, port);
                server.Start();
                Log("Successfully listening on 0.0.0.0:" + port);
            }
            catch (Exception ex)
            {
                Log("FAILED TO BIND PORT " + port + ": " + ex.ToString());
                return;
            }

            // Main accept loop
            while (isRunning)
            {
                try
                {
                    TcpClient client = server.AcceptTcpClient();
                    ThreadPool.QueueUserWorkItem(HandleClient, client);
                }
                catch (SocketException ex)
                {
                    Log("Server socket stopped: " + ex.Message);
                    break;
                }
                catch (Exception ex)
                {
                    Log("Accept error: " + ex.Message);
                }
            }

            Log("Daemon Main loop ended. Process exiting.");
        }

        #endregion
    }
}
