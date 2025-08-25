import tkinter as tk
import tkinter.filedialog as fd
import re
import os.path
import sys

#GLOBALS
filename = "Untitled"

#opcode dictionary
opcode = {
	"NOP": "0001",
	"CALL": "0010",
	"RET": "0011",
	"JMP": "0100",
	"BRZ": "0101",
	"BRN": "0110",
	"BRP": "0111",
	"BRC": "1000",
	"BRV": "1001",
	"LDR": "1010",
	"LDW": "1011",
	"LDI": "1100",
	"STR": "1101",
	"STW": "1110",
	"STI": "1111"
}

#funct dictionary
funct = {
	"ADD": "00000",
	"SUB": "00001",
	"AND": "00010",
	"OR": "00011",
	"NOT": "00100",
	"XOR": "00101",
	"ADDI": "00110",
	"SUBI": "00111",
	"ANDI": "01000",
	"ORI": "01001",
	"XORI": "01010",
	"LSL": "01011",
	"LSR": "01100",
	"ADDC": "01101",
	"SUBC": "01110",
	"PUSH": "01111",
	"POP": "10000",
	"SETC": "10001",
	"CLRC": "10010",
	"SETV": "10011",
	"CLRV": "10100"
}

#register address dictionary
register = {
	"r0": "0000",
	"r1": "0001",
	"r2": "0010",
	"r3": "0011",
	"r4": "0100",
	"r5": "0101",
	"r6": "0110",
	"r7": "0111",
	"r8": "1000",
	"r9": "1001",
	"r10": "1010",
	"r11": "1011",
	"r12": "1100",
	"r13": "1101",
	"r14": "1110",
	"r15": "1111"
}

#GPIO register address dictionary
GPIO_register = {
	"GPIOA_IN": "1001000000001111",
	"GPIOA_OUT": "1001000000010000",
	"GPIOA_DDR": "1001000000100000",
	"GPIOA_IOF": "1001000000110000"
}

#CLASSES
class LineNumbers(tk.Text):
	def __init__(self, master, text_widget, **kwargs):
			super().__init__(master, **kwargs)
			self.configure(takefocus=0)

			self.text_widget = text_widget
			self.text_widget.bind('<KeyRelease>', self.redraw)
			self.text_widget.bind('<MouseWheel>', self.redraw)
			self.text_widget.bind('<FocusIn>', self.redraw)
			self.text_widget.bind('<Button-1>', self.redraw)

			self.insert("1.0", '0')
			self.configure(state=tk.DISABLED)

	def redraw(self, event=None):
		#get the first visible index
		start = self.text_widget.index('@0,0').split('.')[0]
		start = int(start)-1
		#get the end
		end = self.text_widget.index(tk.END).split('.')[0]
		end = int(end)-1

		#create a line num index for each visible line
		line_numbers_string = "\n".join(str(start + no) for no in range(end-start))

		self.configure(state=tk.NORMAL)
		self.delete("1.0", tk.END)
		self.insert("1.0", line_numbers_string)
		self.configure(state=tk.DISABLED)

#FUNCTIONS
def compileAsm():
	global filename
	#create output file
	try:
		binfile = fd.asksaveasfile(mode='w')
		binfile.seek(0) #go to the beggining of the file
		binfile.truncate() #remove all data from the file

		asm_in = textArea.get("1.0", "end")
		asmlines = re.split("\n", asm_in)
		for i in range (len(asmlines)):
			if (asmlines[i] != ""):
				binfile.write(decode(asmlines[i]) + "\n")
		binfile.close()
	except:
		print("Exception Occurred!")

def decode(asm):
	global opcode
	global funct
	global register
	global GPIO_register

	asm_split = re.split(" |, ", asm)
	args = []
	#gather the arguments
	for i in range (len(asm_split)):
		if (asm_split[i] != ""):
			args.append(asm_split[i])

	#set the defaults
	op = "0000"
	Rs = "0000"
	Rt = "0000"
	fnct = "00000"
	Rd = "0000"
	Immediate1 = "00000000"
	Immediate2 = "00000000"

	instruction = ""

	#convert any non-binary string to binary
	for j in range (len(args)):
		if args[j] in GPIO_register:
			args[j] = GPIO_register[args[j]]
		elif args[j] in register:
			args[j] = register[args[j]]

	#register format if the opcode is not in the dictionary
	if args[0] in opcode:
		op = opcode[args[0]]
		#test for branch format
		if branchFormatCheck(args[0]):
			if args[0] != "NOP" and args[0] != "RET":
				Immediate1 = args[1][:8]
			instruction = op + "00000000" + Immediate1 + "0000" + "00000000"
		#test for addressing format
		elif addressFormatCheck(args[0]):
			if args[0] == "LDW" or args[0] == "STW":
				if args[0] == "LDW":
					Rd = args[1]
					Immediate2 = args[2]
				else: #otherwise STW
					Rs = args[1][:4]
					Rt = args[1][4:8]
					Immediate1 = args[1][-8:]
					Immediate2 = args[2]
			elif args[0] == "LDI" or args[0] == "STI":
				Immediate2 = args[3]
				if args[0] == "LDI": #LDI Rs, Rd, Immediate2
					Rs = args[1]
					Rd = args[2]
				else: #otherwise STI Rs, Rt, Immediate2
					Rs = args[1]
					Rt = args[2]
			else: #otherwise LDR or STR
				Immediate1 = args[2][:8]
				Immediate2 = args[2][-8:]
				if args[0] == "LDR":
					Rd = args[1]
				else: #otherwise STR
					Rs = args[1]
			instruction = op + Rs + Rt + Immediate1 + Rd + Immediate2
	else:
		#in the register format
		# inputs given in the order of Rs, Rt, Rd, Immediate2
		fnct = funct[args[0]]
		#if it is an immediate function
		if args[0] == "ADDI" or args[0] == "SUBI" or args[0] == "ANDI" or args[0] == "ORI" or args[0] == "XORI":
			Rs = args[1]
			Rd = args[2]
			Immediate2 = args[3]
		#else if it is push
		elif args[0] == "PUSH":
			Rs = args[1]
		#else if it is pop
		elif args[0] == "POP":
			Rd = args[1]
		#otherwise
		elif args[0] != "SETC" and args[0] != "CLRC" and args[0] != "SETV" and args[0] != "CLRV":
			Rs = args[1]
			if args[0] != "LSL" and args[0] != "LSR" and args[0] != "NOT":
				Rt = args[2]
				Rd = args[3]
			else:
				Rd = args[2]
		instruction = op + Rs + Rt + fnct + "000" + Rd + Immediate2

	return instruction

def addressFormatCheck(op):
	if op == "LDR" or op == "LDW" or op == "LDI" or op == "STR" or op == "STW" or op == "STI":
		return True
	else:
		return False

def branchFormatCheck(op):
	if op == "NOP" or op == "CALL" or op == "RET" or op == "JMP" or op == "BRZ" or op == "BRN" or op == "BRP" or op == "BRC" or op == "BRV":
		return True
	else:
		return False

def setTitle(window, filename):
	window.title("POM8 Assembler [" + filename + "]")

def openFile():
	global filename
	try:
		asmfile = fd.askopenfile(mode="r")
		if asmfile is not None:
			filename = asmfile.name
			asmfile.seek(0) #go to the beginning of the file
			asmdata = asmfile.read()
			textArea.delete("1.0", "end - 1c")
			textArea.insert("1.0", asmdata)
			asmfile.close()
			#enable save option
			filemenu.entryconfig(filemenu.index("Save"), state=tk.NORMAL)
			setTitle(root, filename)
			ln.redraw()
			root.focus()
	except:
		print("Exception Occurred!")

def saveFile():
	global filename
	try:
		asmfile = open(filename, "w")
		asmdata = textArea.get("1.0", "end - 1c")
		asmfile.seek(0) #go to the beginning of the file
		asmfile.truncate() #remove all data from the file
		asmfile.write(asmdata)
		asmfile.close()
	except:
		print("Exception Occurred!")

def saveFileAs():
	global filename
	try:
		asmfile = fd.asksaveasfile(mode='w')
		if asmfile is not None:
			filename = asmfile.name
			asmdata = textArea.get("1.0", "end - 1c")
			asmfile.seek(0) #go to the beginning of the file
			asmfile.truncate() #remove all data from the file
			asmfile.write(asmdata)
			asmfile.close()
			#enable save option
			filemenu.entryconfig(filemenu.index("Save"), state=tk.NORMAL)
			setTitle(root, filename)
			root.focus()
	except:
		print("Exception Occurred!")

def exitApp():
	root.destroy()
	sys.exit()

#creating the TKinter window
root = tk.Tk()
setTitle(root, filename)

#tool bar
menubar = tk.Menu(root)
# file cascade menu
filemenu = tk.Menu(menubar, tearoff=0)
filemenu.add_command(label="Open", command=openFile)
filemenu.add_command(label="Save", command=saveFile, state=tk.DISABLED)
filemenu.add_command(label="Save As...", command=saveFileAs)
filemenu.add_command(label="Exit", command=exitApp)
menubar.add_cascade(label="File", menu=filemenu)
# compile button
menubar.add_command(label="Compile", command=compileAsm)
# add the tool bar to the window
root.config(menu=menubar)

#frame
textEditor = tk.Frame(root)
textEditor.pack(side=tk.TOP, fill=tk.BOTH, expand=True)

#text area to code in
textArea = tk.Text(textEditor, wrap=tk.NONE, padx=5, pady=5)

#line numbers
ln = LineNumbers(textEditor, textArea, width=3, pady=5)

textArea.pack(side=tk.RIGHT, fill=tk.BOTH, expand=True)
ln.pack(side=tk.RIGHT, fill=tk.Y)

root.mainloop()
