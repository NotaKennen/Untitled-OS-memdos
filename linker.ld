ENTRY(start)

SECTIONS
{
	. = 0x9500;

	.text BLOCK(1):
	{
		*(.text)
	}
}