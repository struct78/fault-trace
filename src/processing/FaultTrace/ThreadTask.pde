public class ThreadTask extends TimerTask {
 Thread thread;
 ThreadTask(Thread thread) {
	 this.thread = thread;
 }

 public void run() {
	 thread.setDaemon(true);
	 thread.start();
 }
}
