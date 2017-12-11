public class StateManager {
	public Calendar date;
	public color colour;
	public color background;
	public long delay;

	public StateManager( Calendar date, color colour, color background, long delay ) {
		this.date = date;
		this.colour = colour;
		this.background = background;
		this.delay = delay;
	}
}

public class StateManagerThread extends Thread {
	 Calendar date;
	 ArrayList<StateManager> states;
	 color colour;
	 color background = Configuration.Palette.Background.Start;

	 StateManagerThread(ArrayList<StateManager> states) {
		 this.states = states;
	 }

	 public void run() {
		try {
		 for ( StateManager state : this.states ) {
			this.date = state.date;
			this.colour = state.colour;
			this.background = state.background;
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

	public color getBackground() {
		return this.background;
	}
}
