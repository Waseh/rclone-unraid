<?PHP
if($_POST['action'] == 'copy') {
  $source = $_POST['path'];
  $destination = "/boot/config/plugins/user.scripts/scripts";
  shell_exec("cp -r $source $destination");
}
?>
