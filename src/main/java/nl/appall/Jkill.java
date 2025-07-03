package nl.appall;

import picocli.CommandLine;
import picocli.CommandLine.Command;
import picocli.CommandLine.Option;
import picocli.CommandLine.Parameters;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.util.concurrent.Callable;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

@Command(name = "jkill", version = "jkill 1.0",
        description = "Kill processes running on specified port")
public class Jkill implements Callable<Integer> {

    @Parameters(index = "0", description = "Port number to kill processes on")
    private int port;

    @Option(names = {"-h", "--help"}, usageHelp = true, description = "Show this help message and exit")
    private boolean helpRequested = false;

    @Option(names = {"-V", "--version"}, versionHelp = true, description = "Print version information and exit")
    private boolean versionRequested = false;

    public static void main(String... args) {
        int exitCode = new CommandLine(new Jkill()).execute(args);
        System.exit(exitCode);
    }

    @Override
    public Integer call() throws Exception {
        try {
            String os = System.getProperty("os.name").toLowerCase();

            if (os.contains("win")) {
                return killProcessOnPortWindows(port);
            } else {
                return killProcessOnPortUnix(port);
            }
        } catch (Exception e) {
            System.err.println("Error: " + e.getMessage());
            return 1;
        }
    }

    private int killProcessOnPortUnix(int port) throws IOException, InterruptedException {
        String[] findCommand = {"lsof", "-ti", ":" + port};
        Process findProcess = new ProcessBuilder(findCommand).start();

        BufferedReader reader = new BufferedReader(new InputStreamReader(findProcess.getInputStream()));
        String line;
        boolean foundProcesses = false;

        while ((line = reader.readLine()) != null) {
            String pid = line.trim();
            if (!pid.isEmpty()) {
                foundProcesses = true;
                System.out.println("Killing process " + pid + " on port " + port);

                String[] killCommand = {"kill", "-9", pid};
                Process killProcess = new ProcessBuilder(killCommand).start();
                int killExitCode = killProcess.waitFor();

                if (killExitCode == 0) {
                    System.out.println("Successfully killed process " + pid);
                } else {
                    System.err.println("Failed to kill process " + pid);
                    return 1;
                }
            }
        }

        int findExitCode = findProcess.waitFor();

        if (!foundProcesses) {
            if (findExitCode == 0) {
                System.out.println("No processes found running on port " + port);
            } else {
                System.err.println("Error finding processes on port " + port + ". Make sure 'lsof' is installed.");
                return 1;
            }
        }

        return 0;
    }

    private int killProcessOnPortWindows(int port) throws IOException, InterruptedException {
        String[] findCommand = {"netstat", "-ano"};
        Process findProcess = new ProcessBuilder(findCommand).start();

        BufferedReader reader = new BufferedReader(new InputStreamReader(findProcess.getInputStream()));
        String line;
        Pattern pattern = Pattern.compile("\\s+TCP\\s+\\S*:" + port + "\\s+\\S+\\s+LISTENING\\s+(\\d+)");
        boolean foundProcesses = false;

        while ((line = reader.readLine()) != null) {
            Matcher matcher = pattern.matcher(line);
            if (matcher.find()) {
                String pid = matcher.group(1);
                foundProcesses = true;
                System.out.println("Killing process " + pid + " on port " + port);

                String[] killCommand = {"taskkill", "/F", "/PID", pid};
                Process killProcess = new ProcessBuilder(killCommand).start();
                int killExitCode = killProcess.waitFor();

                if (killExitCode == 0) {
                    System.out.println("Successfully killed process " + pid);
                } else {
                    System.err.println("Failed to kill process " + pid);
                    return 1;
                }
            }
        }

        int findExitCode = findProcess.waitFor();

        if (!foundProcesses) {
            if (findExitCode == 0) {
                System.out.println("No processes found running on port " + port);
            } else {
                System.err.println("Error finding processes on port " + port);
                return 1;
            }
        }

        return 0;
    }
}