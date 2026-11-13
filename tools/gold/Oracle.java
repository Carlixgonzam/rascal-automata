import gold.structures.turingMachine.*;
import gold.util.GTuringMachines;
import java.io.*;
import java.util.*;

public class Oracle {
  public static void main(String[] args) throws Exception {
    Map<String, GTuringMachine> machines = new HashMap<>();
    for (File f : new File(args[0]).listFiles()) {
      if (!f.getName().endsWith(".txt")) continue;
      GTuringMachine m = GTuringMachines.read(new FileInputStream(f), new gold.visualization.turingMachine.GTuringMachineLayoutSketch(0));
      machines.put(m.getName(), m);
    }
    for (int a = 1; a < args.length; a += 3) {
      String name = args[a];
      String sigma = args[a + 1];
      int n = Integer.parseInt(args[a + 2]);
      List<String> words = new ArrayList<>(List.of(""));
      for (int k = 0, from = 0; k < n; k++) {
        int to = words.size();
        for (int i = from; i < to; i++) for (char c : sigma.toCharArray()) words.add(words.get(i) + c);
        from = to;
      }
      for (String w : words) {
        GTuringMachine m = machines.get(name);
        GTuringMachine.Tape tape = new GTuringMachine.Tape(("#" + w + "#").toCharArray());
        String out;
        try {
          m.execute(machines, tape, false, new ITuringMachineListener() { public void executionStarted(GTuringMachine x, GTuringMachine.Tape t) {} public void stepPerformed(GTuringMachine.Configuration c, GTuringMachine.Tape t, GTuringMachineEdge e, int i) {} public void executionFinished(GTuringMachine x, GTuringMachine.Tape t) {} });
          StringBuilder sb = new StringBuilder();
          for (int i = 0; i < tape.getLimit(); i++) sb.append(tape.read(i));
          String t = sb.toString().replaceAll("#+$", "");
          out = "ok " + tape.getHead() + " " + (t.isEmpty() ? "#" : t);
        } catch (Exception e) {
          String msg = String.valueOf(e.getMessage());
          out = "error " + (msg.contains("left end") ? "left" : msg.contains("last cell") ? "right" : msg.contains("steps") ? "steps" : msg.contains("two transitions") ? "two" : "other:" + msg);
        }
        System.out.println(name + " " + (w.isEmpty() ? "λ" : w) + " " + out);
      }
    }
  }
}
