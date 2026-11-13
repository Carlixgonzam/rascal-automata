import gold.structures.automaton.*;
import java.io.*;
import java.lang.reflect.*;
import java.util.*;

public class Pda {
  static Object call(Object target, String name, Object... args) throws Exception {
    for (Method m : target.getClass().getMethods()) {
      if (m.getName().equals(name) && m.getParameterCount() == args.length) {
        m.setAccessible(true);
        return m.invoke(target, args);
      }
    }
    throw new RuntimeException("no method " + name + "/" + args.length);
  }
  public static void main(String[] args) throws Exception {
    List<String> lines = new ArrayList<>();
    BufferedReader in = new BufferedReader(new FileReader(args[0]));
    for (String l; (l = in.readLine()) != null; ) if (!l.isBlank()) lines.add(l);
    Set<String> states = new LinkedHashSet<>(Arrays.asList(lines.get(0).split(" ")));
    Set<Character> sigma = new LinkedHashSet<>(); for (char c : lines.get(1).toCharArray()) sigma.add(c);
    Set<Character> gamma = new LinkedHashSet<>(); for (char c : lines.get(2).toCharArray()) gamma.add(c);
    String start = lines.get(3);
    Set<String> finals = new LinkedHashSet<>(Arrays.asList(lines.get(4).split(" ")));
    GPushdownAutomaton<String> m = new GPushdownAutomaton<>(states, sigma, gamma, start, finals);
    for (String l : lines.subList(5, lines.size())) {
      String[] p = l.split(" ", -1);
      String read = p[2].equals("_") ? "" : p[2];
      Object d = call(m, "delta", p[0], p[1], read);
      Object[] ops = Arrays.copyOfRange(p, 4, p.length);
      call(d, p[3], ops);
    }
    String alphabet = args[1];
    int n = Integer.parseInt(args[2]);
    List<String> words = new ArrayList<>(List.of(""));
    for (int k = 0, from = 0; k < n; k++) {
      int to = words.size();
      for (int i = from; i < to; i++) for (char c : alphabet.toCharArray()) words.add(words.get(i) + c);
      from = to;
    }
    for (String w : words) System.out.println((w.isEmpty() ? "λ" : w) + " " + m.acceptsString(w));
  }
}
