Ti=CRUD

1.Ti=Create

1.sec=Create: i) an empty File with a user-determined name so the use can start a new editing exercise; ii) from a File, create a new File with the current File referenced at the bottom (extending, revising the current File). 

2.Ti=Read

2.sec=In a peer-to-peer system, "read" can be understood as Peer2 obtaining one or more files from Peer1, which Peer2 stores in Peer2's PDS.  Read can be done by http, git, ftp, etc.  The variants on this - caching and presenting in a browser for instance - can be seen as being either insecure or not-yet secured.

3.Ti=Update

3.sec=The issue of versioning has many levels.  Git provides at floor, and a very good one.  But we need at least one other idea.  We need a notion of next-draft.  That can be done in the Cmacc model by making a new File2 that has a Key/Value list of changes and references the old File1.  In some settings, we will want the names of these Files to indicate their order and meaning.  This is a very wide practice in law and elsewhere.  It corresponds to the practice in software release versioning.  For the moment, we have chosen a convention of adding a _01.md at the end of File names, with _0.md being the current, without guarantee of stability other than the git history.  The _01.md numbers currently have no technical guarantee of stability, it is more a promise by the maintainer than a certainty.  If we use hashed names, this issue disappears, but another one arises of naming, organizing, efficiently using .gitinclude, etc. 

4.Ti=Delete

4.sec=i) delete the File, ii) delete the contents of the File, but leave it's name (useful for proof, particularly for Files with hashed names).  Deletion can be an immediate result of the operator action, or can be programmed.  Programmed deletes are very important for a DRY platform.

5.Ti=Render

5.sec=Render is some forms of "read."  Render has at least four formats - i) Print, ii) Doc, iii) Xray, iv) a list of each of the Key/Values used in the Doc view (complete Doc, but without object model). 

6.Ti=Access

6.sec=Perhaps "access" is an aspect of each of the CRUD operations.

=[Z/ol/6]