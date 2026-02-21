import java.util.*; public class Test { public static void main(String[] args) { String s = "00020501"; String[] arr = s.split("(?<=\G..)"); System.out.println(Arrays.toString(arr)); } }
