// Rateio da Fatura - abridor do aplicativo.
// O executável carrega a página (app.html) embutida, grava em
// %LOCALAPPDATA%\RateioFatura e abre numa janela própria do Microsoft Edge.
// Os dados ficam no banco (Supabase), com uma cópia no navegador, nesse mesmo caminho.
using System;
using System.Diagnostics;
using System.IO;
using System.Reflection;
using System.Windows.Forms;

[assembly: AssemblyTitle("Rateio da Fatura")]
[assembly: AssemblyProduct("Rateio da Fatura")]
[assembly: AssemblyVersion("1.0.1.0")]

static class Program
{
    [STAThread]
    static void Main()
    {
        try
        {
            string dir = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "RateioFatura");
            Directory.CreateDirectory(dir);
            string page = Path.Combine(dir, "rateio-fatura.html");

            byte[] html;
            using (Stream s = Assembly.GetExecutingAssembly().GetManifestResourceStream("app.html"))
            using (MemoryStream m = new MemoryStream())
            {
                s.CopyTo(m);
                html = m.ToArray();
            }
            if (!File.Exists(page) || !SameBytes(File.ReadAllBytes(page), html))
                File.WriteAllBytes(page, html);

            string url = new Uri(page).AbsoluteUri;
            string edge = FindEdge();
            if (edge != null)
                Process.Start(edge, "--app=\"" + url + "\"");
            else
                Process.Start(new ProcessStartInfo(page) { UseShellExecute = true });
        }
        catch (Exception e)
        {
            MessageBox.Show("Não foi possível abrir o Rateio da Fatura.\n\n" + e.Message, "Rateio da Fatura", MessageBoxButtons.OK, MessageBoxIcon.Error);
        }
    }

    static string FindEdge()
    {
        string[] roots = {
            Environment.GetEnvironmentVariable("ProgramFiles(x86)"),
            Environment.GetEnvironmentVariable("ProgramFiles"),
            Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData)
        };
        foreach (string r in roots)
        {
            if (string.IsNullOrEmpty(r)) continue;
            string p = Path.Combine(r, @"Microsoft\Edge\Application\msedge.exe");
            if (File.Exists(p)) return p;
        }
        return null;
    }

    static bool SameBytes(byte[] a, byte[] b)
    {
        if (a.Length != b.Length) return false;
        for (int i = 0; i < a.Length; i++) if (a[i] != b[i]) return false;
        return true;
    }
}
