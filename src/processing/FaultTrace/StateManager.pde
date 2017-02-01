public class StateManager {
	public Calendar date;
	public color colour;
	public long delay;

	public StateManager( Calendar date, color colour, long delay ) {
		this.date = date;
		this.colour = colour;
		this.delay = delay;
	}
}

public class StateManagerThread extends Thread {
	 Calendar date;
	 ArrayList<StateManager> states;
	 color colour;

	 StateManagerThread(ArrayList<StateManager> states) {
		 this.states = states;
	 }

	 public void run() {
		try {
		 for ( StateManager state : this.states ) {
			this.date = state.date;
			this.colour = state.colour;
			if (state.delay>0) {
				Thread.sleep(state.delay);
			}
		 }
		}
		catch(Exception e){
			println(e);
		}
	}

	public Calendar getDate() {
		return this.date;
	}

	public color getColour() {
		return this.colour;
	}
}
