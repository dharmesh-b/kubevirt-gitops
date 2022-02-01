#!/bin/sh

echo "Starting install script"
cd /scripts

IMAGES_NS=$(kubectl get ns | awk '/(kubevirt|openshift-virtualization)-os-images/ {print $1}')
KC=kubectl

${KC} apply -f windows-install-vm.yaml
echo "Applied VM, waiting for VM to start"
sleep 5
vm_ready=$(${KC} get vm windows-install -o jsonpath='{.status.ready}')
while [ "$vm_ready" != "true" ]
do
    sleep 10
    vm_ready=$(${KC} get vm windows-install -o jsonpath='{.status.ready}')
done

echo "VM is started. Waiting for VMI to finish successfully."
vmi_phase=$(${KC} get vmi windows-install -o jsonpath='{.status.phase}')
while [ "$vmi_phase" != "Succeeded" ]
do
    sleep 30
    vmi_phase=$(${KC} get vmi windows-install -o jsonpath='{.status.phase}')
done

echo "VM has finished installing"
${KC} apply -n ${IMAGES_NS} -f clone-boot-source.yaml
echo "Applied DataVolume to clone boot source image"

sleep 5
dv_phase=$(${KC} -n ${IMAGES_NS} get dv win2k19 -o jsonpath='{.status.phase}')
while [ "$dv_phase" != "Succeeded" ]
do
    sleep 10
    dv_phase=$(${KC} -n ${IMAGES_NS} get dv win2k19 -o jsonpath='{.status.phase}')
    echo $dv_phase
done

echo "Cleaning up"
${KC} delete -f windows-install-vm.yaml

my_app_name=$(${KC} get cm windows-install-scripts -o jsonpath='{.metadata.labels.app\.kubernetes\.io/instance}')

echo "Finished"
