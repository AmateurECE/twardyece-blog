# Ext4

## Defragmentation

* Defragmentation is only something that needs to occur for spinning disk
  technology.

## Storage Medium Technologies

* NAND Flash:
  * Suffers from read-disturb. See the Wikipedia page. Mitigation is to rewrite
    NAND pages internally. When will refresh cycles happen? Do SCSI disks
    guarantee that refreshes won't happen in certain states?

* Journaling is 

* Logical Block Addressing?

* File system corruption and data corruption are not the same!
* [Some reads fail, and there's nothing you can do about that.][1]

* [Also, the position of the head on a magnetic HDD is controlled with
electro-magnets. If power fails in the middle of a write, it is possible for
some data to continue to be written while the heads move, corrupting data on
blocks that the filesystem never intended to be written][2].
* The hard drive tells the OS if it uses a write behind cache, and the OS takes
measures to ensure they are flushed in the correct order. Also drives are
designed so that when the power fails, they stop writing. I have seen some
cases where the sector being written at the time of power loss becomes corrupt
because it did not finish updating the ecc ( but can be easily re-written
correctly ), but never heard of random sectors being corrupted on power loss.
* Term: Write Posting, related to Disk Buffer
* [This serverfault post][3] talks about the dangers of out-of-order writes on
  spinning-disk drives.
* [This embedded article][4] talks about the differences between NAND and NOR
  flash.
* [This redditor ran a test][5]. It's unclear how many reps they got, but
  posting their experiment on the internet with little affirmative feedback
  indicates that it's not as much a problem as the community might like to
  believe.

## Internal Byte Shuffling

* Read-disturb prevention
* Wear-leveling
* Flash devices generally store 528-byte sectors in pages which are 32 KiB or
more in size. Requesting a write to a 512-byte sector may cause that sector to
be written to an empty page. If free pages are scarce, the flash controller may
shuffle some data around to free up some pages. See [6].

[1]: https://en.wikipedia.org/wiki/Data_corruption#SILENT
[2]: https://unix.stackexchange.com/a/12701/347919
[3]: https://serverfault.com/a/15539
[4]: https://www.embedded.com/flash-101-nand-flash-vs-nor-flash
[5]: https://www.reddit.com/r/raspberry_pi/comments/jcv5rk/do_microsd_cards_corrupt_in_case_of_sudden_power/
[6]: https://electronics.stackexchange.com/questions/8425/
