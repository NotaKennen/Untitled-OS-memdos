ENTRY(start)

SECTIONS
{
	. = 0x9200;

	.text BLOCK(1):
	{
		*(.text)
	}
}