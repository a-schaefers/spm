# Copyright 1999-2019 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

DESCRIPTION="Simple Power Manager is a programmable shell script daemon that performs actions based on power thresholds."
HOMEPAGE="https://github.com/a-schaefers/simple-power-manager/"
SRC_URI="https://github.com/a-schaefers/${PN}/archive/${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~ppc ~ppc64 ~s390 ~sh ~sparc ~x86"

RDEPEND="sys-power/acpi"

src_install() {
	dobin simple-power-manager
}
