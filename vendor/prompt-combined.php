<?php

echo "<b><a href=i.php><img src='" . ASSETS_PATH . "/CmA-Square.png' height=20>/</a></a></b>";

echo "<a href=i.php?v=l&f=>Docs</a>/<a href=$_SERVER[PHP_SELF]?v=l&f=$rootdir[dirname]/>$rootdir[dirname]</a>/<b>$filenameX</b> 
<br></h4>";

echo " &emsp; Source views: ";

echo "<a href=i.php?v=s&f=$dir>". SOURCE_TAB_MESSAGE."</a> ";

echo "<a href=i.php?v=j&f=$dir>". "JSON(ish)" ."</a> ";

echo " on ";

echo "<a href=" . URLFORDOCSINREPO . substr($dir, URLFORDOCSINREPOOFFSET) . ">GitHub</a> ";

# Open in VSCode

echo  "<a href='vscode://file//Users/jgh/Documents/GitHub/CommonAccord-Org/Doc/$dir'>(VSCode)</a> ";

# echo "<a href=" . URLFORREPO . "/search?utf8=✓&q=" . $dir . ">~PageRank </a>  &emsp; ";

echo " &emsp; Doc views: ";

echo "<b><a href=i.php?v=d&f=$dir&k=$keyName>". DOC_TAB_MESSAGE ."</a></b> ";

echo "(&k=$keyName): ";

echo "<a href=i.php?v=v&f=$dir&k=$keyName>Visual</a> ";

echo "<a href=i.php?v=p&f=$dir&k=$keyName>Print</a> ";

# echo "<a href=i.php?v=edit&f=$dir>".EDIT_TAB_MESSAGE."</a> ";

# echo "<a href=i.php?v=openedit&f=$dir>". COMPLETE_TAB_MESSAGE."</a> ";

echo "Technical: " ;

echo "<a href=i.php?v=m&f=$dir&k=$keyName>". "OpenParameters" ."</a> ";

echo "<a href=i.php?v=x&f=$dir&k=$keyName>Xray</a> ";

# echo "<a href=i.php?v=kvs&f=$dir> KVs</a> ";


?>

################################################################################
<p><input type="button" class="btn btn-primary btn-lg" value="Print" onclick="PrintElem('#box')" /> </p>
	<div id="box" contenteditable="true" style="background:white;padding:40px; width:100%;overflow:auto">

################################################################################
<?echo"<h4><a href=$_SERVER[PHP_SELF]?action=source&file=$dir$f>$f</a></h4>";?>
<? include("footer.php"); ?>
################################################################################
<?php
	$file = $_REQUEST['file'];
	$lib_path = LIB_PATH;
        echo `perl $lib_path/tree-parse.pl $file 2&>1`;
?>

################################################################################
<!DOCTYPE html>
<head>
<link rel='icon' href='vendor/png/CmA-Square.png'>

<title><?php echo $dir ?></title>
<link  href="Doc/G/Z/CSS/Doc.css" rel="stylesheet" />
<link  href="png/custom.css" rel="stylesheet" />

<link href="//maxcdn.bootstrapcdn.com/bootstrap/3.2.0/css/bootstrap.min.css" rel="stylesheet" />
<script src="//ajax.googleapis.com/ajax/libs/jquery/1.11.1/jquery.min.js"></script>
<script src="//maxcdn.bootstrapcdn.com/bootstrap/3.2.0/js/bootstrap.min.js"></script>

  <script src="//code.jquery.com/jquery-1.10.2.js"></script>
  <script src="//code.jquery.com/ui/1.11.1/jquery-ui.js"></script>
  <script>
  $(function() {
    $( "#tabs" ).tabs();
  });
  </script>

</head>

################################################################################
<head>
<meta name="google-site-verification" content="pW9kknEzvWYfcrDUhD2gffPzvVGNEPzrviRkpDQLqys" />
</head>
<body style="margin:40;padding:0">

<?php

$lib_path = LIB_PATH;

$dir=LANDING_MD;

# Adding ability to pass a starting Key to the rendering

if (strlen($keyName) < 2) { 
  $keyName = "r00t";
}

$document = `perl $lib_path/parser.pl $path/$dir $keyName `;


if (strlen($document) > 1){ 
 
  echo $document;}
 else {
   echo "Nothing to Show";


}
?>

################################################################################
</div></div></div></div>
<div id="footer">
		<p style="text-align:center;"><a href="#">Terms of Service</a> | <a href="#">Privacy Policy</a> <img height=50 src="<?php echo ASSETS_PATH; ?>/cc.png"> CommonAccord 2017</p>
</div>
</html>

################################################################################
<?php
/*require('./Code/autoload.php'); */
ini_set("allow_url_include", true);
include("header.php");

?>

<div class="container">

<table class="responsive">
   <h3 class="title">&#10003; Codified Documents &nbsp; &nbsp; &#10003; Structured Relationships  &nbsp; &nbsp; &#10003; Ready for Personal Data Stores</h3>
     
   <p>Legal systems can be codified as "objects" in a "graph."
<br/><br/>
    <table class="table table-striped table-condensed table-bordered" style="padding:20px">

<tr>
<td><img src="http://cdns2.freepik.com/free-photo/group--persons-outline--ios-7-interface-symbol_318-35219.jpg" height="50px"/></td>
<td width="30p"><a href=<?=$_SERVER['PHP_SELF']?>?action=list&file=core/id/>id</a></td>
				 <td>People come first.  They have relationships, own things, are places.</td>
</tr>

<tr>
<td><img src="https://cdn0.iconfinder.com/data/icons/seo-smart-pack/128/grey_new_seo2-31-512.png" height="50px"></td>
<td><a href=<?=$_SERVER['PHP_SELF']?>?action=list&file=core/ids/>ids</a></td>
				 <td>ID<u>s</u> are combinations of persons.  Parties to a contract.  Suppliers, customers.  Employees, board members, agents, subsidiaries.  Regulators.  Friends with whom you share something important.</td></tr>

<tr>
<td><img src="http://be-my-guest.com/static/img/things-to-do-icons.png" height="50px"></td>
<td><a href=<?=$_SERVER['PHP_SELF']?>?action=list&file=core/re/>re</a></td>
<td>"Re" is for things.  Mostly things that a person can own or sell, license, borrow or otherwise exchange.  /auto, /ip/patent/, /real, etc.  To be tied with registration systems such as deed registries, DMVs, patent offices, etc.</td></tr>

<tr>
<td><img src="http://images.clipartpanda.com/world-map-clip-art-worldmap.gif" height="50px"></td>
<td><a href=<?=$_SERVER['PHP_SELF']?>?action=list&file=core/at/>at</a></td>
<td>"At" is for places.   1 Broadway, Cambridge MA, USA becomes at/usa/ma/middlesex/cambridge/broadway/1/geo.</td></tr>

<tr>
<td><img src="http://www.lakelocal.org/forms/PublishingImages/forms-icon.jpg"height="50px"></td>
<td><a href=<?=$_SERVER['PHP_SELF']?>?action=list&file=core/gov/>gov</a></td>
   <td>Government forms.  Applications, permits, reports. Linked to codes, regulations and laws.  Adjacent to at/ and /form.</td>
</tr>

<tr>
<td><img src="http://www.lakelocal.org/forms/PublishingImages/forms-icon.jpg" height="50px"></td>
				 <td><a href=<?=$_SERVER['PHP_SELF']?>?action=list&file=core/form/>form</a></td><td>Forms are templates, model documents, boilerplate and other codified text.  Contracts, permits, pleadings, adaptations for particular jurisdictions and the like.</td>
</tr>

<tr>
<td><img src="http://www.lakelocal.org/forms/PublishingImages/forms-icon.jpg"height="50px"></td>
<td><a href=<?=$_SERVER['PHP_SELF']?>?action=list&file=doc/>doc</a></td><td>Docs are events in a legal system.  Making an application, granting a permit, signing a deal, sending a draft.  Each is a connection between some persons, a form and a history. History is the chain of events, the succession of documents.</td>
</tr>
	</table>
	</table>
<style>
	#filelist { 
		display: none;
	}
</style>

################################################################################
<?php
error_reporting(E_ALL);
$path = ROOT . '/Doc/';
ini_set("allow_url_include", true);

$Text_Edit_Window_Size = 'cols=120 rows=30' ;

if (!isset($_REQUEST[VIEW])) {
    $_REQUEST[VIEW] = "landing";
}

if (!isset($_REQUEST[KEYNAME])) {
    $_REQUEST[KEYNAME] = "r00t";
}

if (isset($_REQUEST[FILENAME])) {
    $dir = $_REQUEST[FILENAME];
    $dir = preg_replace('~[^\w/.,_-]~u', '_', $dir);
    $dir = str_replace('..', '', $dir);
} else {
    $dir = './';
}

//let each view have access to the file path and name

        $rootdir = pathinfo($dir);
        $filenameX = basename($dir);
        $lib_path = LIB_PATH;
        $viewName = $_REQUEST[VIEW] ;
        $keyName = $_REQUEST[KEYNAME] ;
        $openForm = $_REQUEST['open'] ;
//Make key default of "Model.Root"
        

switch ($_REQUEST[VIEW]) {

    case 'c':
    case 'cicero':
        include('./vendor/cmacc-app/view/cicero.php');
        break;

    case 'd':
    case 'doc':
        include('./vendor/cmacc-app/view/doc.php');
        break;

    case 'l':
    case 'list':
        include('./vendor/cmacc-app/view/list.php');
        break;

    case 'landing':
        include($_REQUEST[VIEW] . '.php');
        break;

    case 'm':
    case 'missing':
        include('./vendor/cmacc-app/view/missing.php');
        break;

    case 'o':
    case 'openedit':
            include('./vendor/cmacc-app/view/openedit.php');
            break;
            
    case 'p':
    case 'print':
        include('./vendor/cmacc-app/view/print.php');
        break;
    
    case 't':    
    case 'trace':
        include('./vendor/cmacc-app/view/trace.php');
        break;

    case 'v':
    case 'visual':
        include('./vendor/cmacc-app/view/visual.php');
        break;

    case 'x':
    case 'xray':
        include('./vendor/cmacc-app/view/xray.php');
        break;
    
    case 's':
    case 'source':

        if (isset($_REQUEST['submit'])) {

            $file_name = $path . $dir;

            if (file_exists($file_name)) {

                if (is_writeable($file_name)) {
                    $fp = fopen($file_name, "w");
                    $data = $_REQUEST['newcontent'];
                    $data = preg_replace('/\r\n/', "\n", $data);
                    $data = trim($data);
                    fwrite($fp, $data);
                    fclose($fp);
                } else {
                    print '<span style="color: red">ERROR: File ' . $dir . ' is not write able.</style>';
                }
            } else {
                print '<span style="color: red">ERROR: File ' . $dir . ' does not exists.</style>';
            }
        }

        $content = file_get_contents($path . $dir, FILE_USE_INCLUDE_PATH);
        $contents = explode("\n", $content);

        //source.php includes the formatting for the table that displays the components of a document
        include("./vendor/cmacc-app/view/source.php");

        break;

   case 'j':
    case 'json':

        if (isset($_REQUEST['submit'])) {

            $file_name = $path . $dir;

            if (file_exists($file_name)) {

                if (is_writeable($file_name)) {
                    $fp = fopen($file_name, "w");
                    $data = $_REQUEST['newcontent'];
                    $data = preg_replace('/\r\n/', "\n", $data);
                    $data = trim($data);
                    fwrite($fp, $data);
                    fclose($fp);
                } else {
                    print '<span style="color: red">ERROR: File ' . $dir . ' is not write able.</style>';
                }
            } else {
                print '<span style="color: red">ERROR: File ' . $dir . ' does not exists.</style>';
            }
        }

        $content = file_get_contents($path . $dir, FILE_USE_INCLUDE_PATH);
        $contents = explode("\n", $content);
        $rootdir = pathinfo($dir);
        $filenameX = basename($dir);

        //source.php includes the formatting for the table that displays the components of a document
        include("./vendor/cmacc-app/view/json.php");

        break;

 
    default:
        echo $_REQUEST[VIEW]. " is not a valid 'view'. Try again.<br>"  ;
       include('./vendor/cmacc-app/view/source.php');
        break;
}


################################################################################
<?
echo "<body style='font-size: 500%;'><a href=$_SERVER[PHP_SELF]?action=list&file=$rootdir[dirname]/>$rootdir[dirname]</a><br><br><br>
<b>$filenameX</b>   (<a href=$_SERVER[PHP_SELF]?action=edit&file=$dir>Edit</a>):  &nbsp;  &nbsp; &nbsp; &nbsp; &nbsp; <a href=$_SERVER[PHP_SELF]?action=render&file=$dir><b>Show the Document</b></a><br><br>

<table rules='none'; border='0'>";

?>
################################################################################