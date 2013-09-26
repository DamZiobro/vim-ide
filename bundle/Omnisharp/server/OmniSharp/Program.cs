using System;
using System.IO;
using System.Threading;
using NDesk.Options;
using Nancy.Hosting.Self;
using OmniSharp.Solution;

namespace OmniSharp
{
    internal static class Program
    {
        private static void Main(string[] args)
        {
            bool showHelp = false;
            string solutionPath = null;

            var port = 2000;
            bool verbose = false;

            var options = new OptionSet
                    {
                        {
                            "s|solution=", "The path to the solution file",
                            s => solutionPath = s
                        },
                        {
                            "p|port=", "Port number to listen on",
                            (int p) => port = p
                        },
                        {
                            "v|verbose", "Output debug information",
                            v => verbose = v != null
                        },
                        {
                            "h|help", "show this message and exit",
                            h => showHelp = h != null
                        },
                    };

            try
            {
                options.Parse(args);
            }
            catch (OptionException e)
            {
                Console.WriteLine(e.Message);
                Console.WriteLine("Try 'omnisharp --help' for more information.");
                return;
            }

            showHelp |= solutionPath == null;

            if (showHelp)
            {
                ShowHelp(options);
                return;
            }

            StartServer(solutionPath, port, verbose);
            
        }

        private static void StartServer(string solutionPath, int port, bool verbose)
        {
            var lockfile = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "lockfile-" + port);

            try
            {
                using (new FileStream(lockfile, FileMode.OpenOrCreate, FileAccess.Read, FileShare.None))
                {
                    var solution = new CSharpSolution(solutionPath);
                    Console.CancelKeyPress +=
                        (sender, e) =>
                            {
                                solution.Terminated = true;
                                Console.WriteLine("Ctrl-C pressed");
                                e.Cancel = true;
                            };

                    var nancyHost = new NancyHost(new Bootstrapper(solution, verbose), new Uri("http://localhost:" + port));

                    nancyHost.Start();

                    while (!solution.Terminated)
                    {
                        Thread.Sleep(1000);
                    }
                    
                    Console.WriteLine("Quit gracefully");
                    nancyHost.Stop();
                }
                DeleteLockFile(lockfile);
            }
            catch (IOException)
            {
                Console.WriteLine("Detected an OmniSharp instance already running on port " + port + ". Press a key.");
                Console.ReadKey();
            }
        }

        private static void DeleteLockFile(string lockfile)
        {
            File.Delete(lockfile);
        }

        static void ShowHelp(OptionSet p)
        {
            Console.WriteLine("Usage: omnisharp -s /path/to/sln [-p PortNumber]");
            Console.WriteLine();
            Console.WriteLine("Options:");
            p.WriteOptionDescriptions(Console.Out);
        }
    }
}
