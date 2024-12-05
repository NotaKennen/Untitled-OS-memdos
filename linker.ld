ENTRY(start)

SECTIONS
{
	. = 0x0;

	.text BLOCK(1):
	{
		*(.text)
	}
}