import serial
from collections import deque
import matplotlib.pyplot as plt
import matplotlib.animation as animation

# Configure serial port (replace with your device)
SERIAL_PORT = "/dev/tty.usbmodem1103"  # Typical Arduino serial port on Mac
BAUD_RATE = 115200

# Configure plot
MAX_POINTS = 200  # Number of points to show in plot
PLOT_INTERVAL = 50  # Animation update interval in ms

# Initialize data buffers
x_accel = deque(maxlen=MAX_POINTS)
y_accel = deque(maxlen=MAX_POINTS)

# Create figure and axes
fig, (ax1, ax2) = plt.subplots(2, 1, sharex=True)
fig.suptitle('Real-time Acceleration Data')
line_x, = ax1.plot([], [], 'r-', label='X-axis')
line_y, = ax2.plot([], [], 'b-', label='Y-axis')

# Configure axes
ax1.set_ylabel('X Acceleration (mg)')
ax2.set_ylabel('Y Acceleration (mg)')
ax2.set_xlabel('Samples')
ax1.grid(True)
ax2.grid(True)
ax1.legend(loc='upper right')
ax2.legend(loc='upper right')

def init_plot():
    ax1.set_xlim(0, MAX_POINTS)
    ax1.set_ylim(-20, 20)
    ax2.set_ylim(990, 1010)
    return line_x, line_y

def update(frame):
    # Read and process all available lines
    while ser.in_waiting > 0:
        try:
            line = ser.readline().decode('utf-8').strip()
            if "Acceleration [mg]:" in line:
                # Parse data line
                parts = line.split()
                x_val = float(parts[1].split(':')[1])
                y_val = float(parts[2])
                
                # Add to buffers
                x_accel.append(x_val)
                y_accel.append(y_val)
        except (UnicodeDecodeError, ValueError, IndexError) as e:
            print(f"Error processing data: {e}")
            continue

    # Update plot data
    line_x.set_data(range(len(x_accel)), x_accel)
    line_y.set_data(range(len(y_accel)), y_accel)
    
    # Auto-scale y-axis
    ax1.relim()
    ax1.autoscale_view(scalex=False)
    ax2.relim()
    ax2.autoscale_view(scalex=False)
    
    return line_x, line_y

# Open serial connection
ser = serial.Serial(SERIAL_PORT, BAUD_RATE, timeout=0.1)

# Start animation
ani = animation.FuncAnimation(
    fig,
    update,
    init_func=init_plot,
    interval=PLOT_INTERVAL,
    blit=True
)

plt.show()

# Close serial port when window is closed
ser.close()